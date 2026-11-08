public import Time
import Kernel_Clock
import Binary
import Console
import Formatter
import IEC_80000_13_Formatting

extension Tests {
    /// Assert that an operation completes within a duration threshold
    ///
    /// Example:
    /// ```swift
    /// try Tests.expect(lessThan: .milliseconds(100)) {
    ///     numbers.sum()
    /// }
    /// ```
    @discardableResult
    public static func expect<T>(
        lessThan threshold: Duration,
        warmup: Int = 0,
        iterations: Int = 10,
        metric: Test.Benchmark.Metric = .median,
        operation: () -> T
    ) throws(Self.Error) -> (result: T, measurement: Test.Benchmark.Measurement) {
        let (result, measurement) = measure(
            warmup: warmup,
            iterations: iterations,
            operation: operation
        )

        let actualDuration = metric.extract(from: measurement)

        guard actualDuration <= threshold else {
            throw Self.Error.benchmarkFailed(
                .thresholdExceeded(
                    test: "",
                    metric: metric,
                    expected: threshold,
                    actual: actualDuration
                )
            )
        }

        return (result, measurement)
    }

    /// Assert that an async operation completes within a duration threshold.
    ///
    /// The operation must be non-throwing (symmetric with the sync overload).
    /// If benchmarking a throwing operation, handle errors inside the closure.
    @discardableResult
    public static func expect<T>(
        lessThan threshold: Duration,
        warmup: Int = 0,
        iterations: Int = 10,
        metric: Test.Benchmark.Metric = .median,
        operation: () async -> T
    ) async throws(Self.Error) -> (result: T, measurement: Test.Benchmark.Measurement) {
        let (result, measurement) = await measure(
            warmup: warmup,
            iterations: iterations,
            operation: operation
        )

        let actualDuration = metric.extract(from: measurement)

        guard actualDuration <= threshold else {
            throw Self.Error.benchmarkFailed(
                .thresholdExceeded(
                    test: "",
                    metric: metric,
                    expected: threshold,
                    actual: actualDuration
                )
            )
        }

        return (result, measurement)
    }
}

extension Tests {
    // WHY: "no regression" is an indivisible semantic concept — splitting across
    //   Swift parameter labels produces awkward signatures that obscure intent.
    // WHEN TO REMOVE: When a Property-based nested accessor (e.g. expect.noRegression)
    //   is available for the Tests namespace.
    // TRACKING: naming-implementation-audit-swift-tests-swift-testing.md N16
    /// Performance regression detector
    ///
    /// Compares current performance against a baseline with tolerance.
    ///
    /// Example:
    /// ```swift
    /// let baseline = Test.Benchmark.Measurement(durations: [.milliseconds(10)])
    /// let (result, measurement) = Tests.measure { operation() }
    ///
    /// Tests.expectNoRegression(
    ///     current: measurement,
    ///     baseline: baseline,
    ///     tolerance: 0.10  // 10% regression allowed
    /// )
    /// ```
    public static func expectNoRegression(
        current: Test.Benchmark.Measurement,
        baseline: Test.Benchmark.Measurement,
        tolerance: Double = 0.10,
        metric: Test.Benchmark.Metric = .median
    ) throws(Self.Error) {
        let comparison = Self.Comparison(
            name: "",
            current: current,
            baseline: baseline,
            metric: metric
        )

        guard comparison.change <= tolerance else {
            throw Self.Error.benchmarkFailed(
                .regressionDetected(
                    test: "",
                    metric: metric,
                    baseline: comparison.baselineValue,
                    current: comparison.currentValue,
                    regression: comparison.change,
                    tolerance: tolerance
                )
            )
        }
    }
}

extension Tests {
    /// Measure performance of an operation
    ///
    /// Runs the operation multiple times with optional warmup iterations,
    /// collecting timing data for statistical analysis.
    @discardableResult
    public static func measure<T>(
        warmup: Int = 0,
        iterations: Int = 10,
        operation: () -> T
    ) -> (result: T, measurement: Test.Benchmark.Measurement) {
        for _ in 0..<warmup {
            _ = operation()
        }

        var durations: [Duration] = []
        durations.reserveCapacity(iterations)
        var lastResult: T?

        for _ in 0..<iterations {
            let start = Clock::Clock.Continuous.now
            lastResult = operation()
            durations.append(Clock::Clock.Continuous.now.offset - start.offset)
        }

        guard let result = lastResult else {
            preconditionFailure("measure requires at least one iteration")
        }
        return (result, Test.Benchmark.Measurement(durations: durations))
    }

    /// Measure performance of an async operation
    @discardableResult
    public static func measure<T, E: Swift.Error>(
        warmup: Int = 0,
        iterations: Int = 10,
        operation: () async throws(E) -> T
    ) async throws(E) -> (result: T, measurement: Test.Benchmark.Measurement) {
        for _ in 0..<warmup {
            _ = try await operation()
        }

        var durations: [Duration] = []
        durations.reserveCapacity(iterations)
        var lastResult: T?

        for _ in 0..<iterations {
            let start = Clock::Clock.Continuous.now
            lastResult = try await operation()
            durations.append(Clock::Clock.Continuous.now.offset - start.offset)
        }

        guard let result = lastResult else {
            preconditionFailure("measure requires at least one iteration")
        }
        return (result, Test.Benchmark.Measurement(durations: durations))
    }

    /// Single-shot timing measurement
    ///
    /// The async overload below shares this name deliberately: the compiler
    /// prefers this synchronous, non-throwing candidate for a plain closure
    /// literal and falls through to the async one only when the body needs it.
    @discardableResult
    public static func time<T>(operation: () -> T) -> (result: T, duration: Duration) {
        let start = Clock::Clock.Continuous.now
        let result = operation()
        return (result, Clock::Clock.Continuous.now.offset - start.offset)
    }

    /// Single-shot timing measurement for async operations
    @discardableResult
    public static func time<T, E: Swift.Error>(
        operation: () async throws(E) -> T
    ) async throws(E) -> (result: T, duration: Duration) {
        let start = Clock::Clock.Continuous.now
        let result = try await operation()
        return (result, Clock::Clock.Continuous.now.offset - start.offset)
    }
}

private let durationFormat = Formatter::Formatter.Duration(numeric: Formatter::Formatter.Number())

extension Tests {
    /// Print a performance measurement summary
    ///
    /// Example:
    /// ```swift
    /// let measurement = Tests.measure(iterations: 100) { operation() }
    /// Tests.report("Operation Name", measurement)
    /// ```
    public static func report(
        _ name: Swift.String,
        _ measurement: Test.Benchmark.Measurement,
        allocations: [Int]? = nil,
        peakMemory: Int? = nil
    ) {
        var output = """
            ⏱️ \(name)
               Iterations: \(measurement.durations.count)
               Min:        \(measurement.min.formatted(durationFormat))
               Median:     \(measurement.median.formatted(durationFormat))
               Mean:       \(measurement.mean.formatted(durationFormat))
               p95:        \(measurement.p95.formatted(durationFormat))
               p99:        \(measurement.p99.formatted(durationFormat))
               Max:        \(measurement.max.formatted(durationFormat))
               StdDev:     \(measurement.standardDeviation.formatted(durationFormat))
            """

        if let allocations, !allocations.isEmpty {
            output += """

                   Allocations:
                     Min:      \((allocations.min() ?? 0).formatted(.bytes(.binary)))
                     Median:   \(allocations.sorted()[allocations.count / 2].formatted(.bytes(.binary)))
                     Max:      \((allocations.max() ?? 0).formatted(.bytes(.binary)))
                     Avg:      \((allocations.reduce(0, +) / allocations.count).formatted(.bytes(.binary)))
                """
        }

        if let peak = peakMemory {
            output += """

                   Peak Memory: \(peak.formatted(.bytes(.binary)))
                """
        }

        print(output)
    }

}

extension Tests {
    /// Console capability detection (cached).
    internal static let consoleCapability = Console.Capability.detect()

    /// Center text within a given width.
    internal static func center(_ text: Swift.String, width: Int) -> Swift.String {
        let padding = width - text.count
        guard padding > 0 else { return text }

        return Swift.String(repeating: " ", count: padding / 2) + text
            + Swift.String(repeating: " ", count: padding - padding / 2)
    }
}

extension Tests {
    /// Print comparison report for multiple benchmarks
    public static func report(comparisons: [Tests.Comparison]) {
        let boxWidth = 58
        let title = "PERFORMANCE COMPARISON REPORT"
        let centeredTitle = center(title, width: boxWidth)

        print("\n╔══════════════════════════════════════════════════════════╗")
        print("║\(centeredTitle)║")
        print("╚══════════════════════════════════════════════════════════╝\n")

        for comparison in comparisons {
            print(comparison.formatted())
            print("")
        }

        let regressions = comparisons.filter { $0.isRegression }.count
        let improvements = comparisons.filter { $0.isImprovement }.count
        let neutral = comparisons.count - regressions - improvements

        let summaryText =
            "Summary: \(improvements) improvements, \(neutral) neutral, \(regressions) regressions"
        let summaryColored = Console.Style.bold.apply(
            to: summaryText,
            capability: consoleCapability
        )
        print(summaryColored)
        print("╚══════════════════════════════════════════════════════════╝\n")
    }
}
