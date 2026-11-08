import File_System
import IO_Kernel
import Kernel
import Kernel_Clock
import Memory_Mapping
import Thread_Pool

extension Test.Trait.Scope.Provider {
    /// Scope provider for timed benchmark measurement.
    public static var timed: Self {
        Self(
            id: "timed",
            priority: 50,
            shouldActivate: { $0[Test.Trait.Timed.self] != nil },
            provideScope: _timedScope
        )
    }

    @Sendable
    private static func _timedScope(
        _ entry: Test.Plan.Entry,
        _ traits: Test.Trait.Collection,
        _ operation: @Sendable () async throws(Error) -> Void
    ) async throws(Error) {
        guard let config = traits[Test.Trait.Timed.self] else {
            preconditionFailure("the timed scope runs only for entries carrying the trait")
        }

        for _ in 0..<config.iteration.warmup {
            try await operation()
        }

        var durations: [Duration] = []
        durations.reserveCapacity(config.iteration.count)
        var allocationStats: [Memory.Allocation.Statistics]? =
            config.evaluation.trackAllocations ? [] : nil

        for _ in 0..<config.iteration.count {
            let before =
                config.evaluation.trackAllocations
                ? Memory.Allocation.Statistics.capture()
                : nil
            let start = Clock::Clock.Continuous.now
            try await operation()
            durations.append(Clock::Clock.Continuous.now.offset - start.offset)
            if let before {
                let after = Memory.Allocation.Statistics.capture()
                allocationStats?.append(Memory.Allocation.Statistics.delta(from: before, to: after))
            }
        }

        let measurement = Test.Benchmark.Measurement(durations: durations)

        let environment = Test.Environment.capture()

        let root = Tests.Baseline.Storage.root()

        var storedBaseline: Test.Benchmark.Measurement? = nil
        var comparison: Tests.Comparison? = nil

        if config.evaluation.baselineTolerance != nil {
            let baselinePath = Tests.Baseline.Storage.path(
                root: root,
                testID: entry.id,
                fingerprint: environment.fingerprint
            )
            let recording = Tests.Baseline.Recording.current

            do throws(Kernel.Thread.Pool.Error) {
                storedBaseline = try await Tests.Baseline.Storage.load(at: baselinePath)
            } catch {}

            if let baseline = storedBaseline {
                comparison = Tests.Comparison(
                    name: entry.id.name,
                    current: measurement,
                    baseline: baseline,
                    metric: config.evaluation.metric
                )

                if recording == .all {
                    do throws(Either<Kernel.Thread.Pool.Error, Tests.Baseline.Storage.Error>) {
                        try await Tests.Baseline.Storage.save(measurement, to: baselinePath)
                    } catch {
                    }
                }
            } else {
                switch recording {
                case .normal, .all:
                    do throws(Either<Kernel.Thread.Pool.Error, Tests.Baseline.Storage.Error>) {
                        try await Tests.Baseline.Storage.save(measurement, to: baselinePath)
                    } catch {
                    }

                case .never:
                    throw .baselineMissing(
                        test: entry.id.name,
                        path: Swift.String(baselinePath)
                    )
                }
            }
        }

        let cv = measurement.coefficientOfVariation
        let mad = measurement.medianAbsoluteDeviation
        let outliers = measurement.outlierCount()
        let trend = Test.Benchmark.Trend.mannKendall(measurement.durations)

        let metricValue = config.evaluation.metric.extract(from: measurement)
        let exceeded = config.evaluation.threshold.map { metricValue > $0 } ?? false
        let factor: Double? =
            if let threshold = config.evaluation.threshold, exceeded {
                metricValue.inSeconds / threshold.inSeconds
            } else {
                nil
            }

        var historyAnalysis: Tests.History.Analysis? = nil

        if Tests.History.Storage.isEnabled {
            let record = Tests.History.Record(
                timestamp: Kernel.Time.realtime(),
                testID: entry.id,
                metric: config.evaluation.metric,
                metricValue: metricValue,
                measurement: measurement,
                environment: environment,
                coefficientOfVariation: cv,
                outlierCount: outliers
            )

            do throws(Either<Kernel.Thread.Pool.Error, Tests.History.Storage.Error>) {
                try await Tests.History.Storage.append(record, root: root)
            } catch {
            }

            let records: [Tests.History.Record]
            do throws(Kernel.Thread.Pool.Error) {
                records = try await Tests.History.Storage.load(
                    root: root,
                    testID: entry.id,
                    fingerprint: environment.fingerprint
                )
            } catch {
                records = []
            }
            historyAnalysis = Tests.History.Analysis.analyze(records)
        }

        let diagnostic = Tests.Diagnostic(
            testName: entry.id.name,
            suiteName: entry.id.suite,
            qualifiedName: entry.id.fullyQualifiedName,
            metric: config.evaluation.metric,
            measurement: measurement,
            environment: environment,
            coefficientOfVariation: cv,
            medianAbsoluteDeviation: mad,
            outlierCount: outliers,
            trend: trend,
            threshold: config.evaluation.threshold,
            exceedanceFactor: factor,
            allocations: allocationStats,
            baseline: storedBaseline,
            comparison: comparison,
            historyAnalysis: historyAnalysis
        )

        Tests.Diagnostic.Collector.shared.append(diagnostic)

        if exceeded, let threshold = config.evaluation.threshold {
            throw .benchmarkFailed(
                .thresholdExceeded(
                    test: entry.id.name,
                    metric: config.evaluation.metric,
                    expected: threshold,
                    actual: metricValue
                )
            )
        }

        if let comparison, let tolerance = config.evaluation.baselineTolerance,
            comparison.change > tolerance
        {
            throw .benchmarkFailed(
                .regressionDetected(
                    test: entry.id.name,
                    metric: config.evaluation.metric,
                    baseline: comparison.baselineValue,
                    current: comparison.currentValue,
                    regression: comparison.change,
                    tolerance: tolerance
                )
            )
        }
    }
}
