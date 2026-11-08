public import Memory_Mapping
public import Sample
public import Time
import Cardinal
import Console
import Formatter
import Tagged

extension Tests {
    /// Structured performance diagnostic aggregating all enrichment data.
    ///
    /// Built by the `.timed` scope provider after measurement. Contains
    /// everything an AI agent or developer needs to diagnose a performance
    /// regression without further computation.
    public struct Diagnostic: Sendable {
        /// Test function name.
        public let testName: Swift.String

        /// Suite name, if any (dot-separated for nested suites).
        public let suiteName: Swift.String?

        /// Fully qualified name: `Module.Suite.name` or `Module.name`.
        public let qualifiedName: Swift.String

        /// The metric that was checked (median, p95, etc.).
        public let metric: Test.Benchmark.Metric

        /// Full measurement with all individual durations and batch statistics.
        public let measurement: Test.Benchmark.Measurement

        /// Runtime and compile-time environment.
        public let environment: Test.Environment

        /// Coefficient of variation (percentage). nil if < 2 iterations.
        public let coefficientOfVariation: Double?

        /// Median Absolute Deviation. nil if empty.
        public let medianAbsoluteDeviation: Duration?

        /// Number of outliers (> 3 MAD from median). nil if empty.
        public let outlierCount: Int?

        /// Temporal trend analysis result.
        public let trend: Test.Benchmark.Trend

        /// Configured threshold, or nil if no threshold was set.
        public let threshold: Duration?

        /// How much the actual value exceeds the threshold (actual / threshold).
        /// nil if no threshold was configured or threshold was not exceeded.
        public let exceedanceFactor: Double?

        /// Allocation statistics per iteration. nil if allocation tracking was not enabled.
        public let allocations: [Memory.Allocation.Statistics]?

        /// Stored baseline measurement, if loaded.
        public let baseline: Test.Benchmark.Measurement?

        /// Comparison result between current and baseline.
        public let comparison: Tests.Comparison?

        /// Cross-run trend analysis from historical records.
        public let historyAnalysis: Tests.History.Analysis?

        public init(
            testName: Swift.String,
            suiteName: Swift.String? = nil,
            qualifiedName: Swift.String,
            metric: Test.Benchmark.Metric,
            measurement: Test.Benchmark.Measurement,
            environment: Test.Environment,
            coefficientOfVariation: Double?,
            medianAbsoluteDeviation: Duration?,
            outlierCount: Int?,
            trend: Test.Benchmark.Trend,
            threshold: Duration?,
            exceedanceFactor: Double?,
            allocations: [Memory.Allocation.Statistics]?,
            baseline: Test.Benchmark.Measurement? = nil,
            comparison: Tests.Comparison? = nil,
            historyAnalysis: Tests.History.Analysis? = nil
        ) {
            self.testName = testName
            self.suiteName = suiteName
            self.qualifiedName = qualifiedName
            self.metric = metric
            self.measurement = measurement
            self.environment = environment
            self.coefficientOfVariation = coefficientOfVariation
            self.medianAbsoluteDeviation = medianAbsoluteDeviation
            self.outlierCount = outlierCount
            self.trend = trend
            self.threshold = threshold
            self.exceedanceFactor = exceedanceFactor
            self.allocations = allocations
            self.baseline = baseline
            self.comparison = comparison
            self.historyAnalysis = historyAnalysis
        }
    }
}

private let durationFormat = Formatter::Formatter.Duration(numeric: Formatter::Formatter.Number())

extension Tests.Diagnostic {

    /// Human-readable formatted diagnostic for console output.
    public func formatted() -> Swift.String {
        let m = measurement
        let cap = Tests.consoleCapability

        var lines: [Swift.String] = []

        if let factor = exceedanceFactor {
            let header = Console.Style.error.apply(
                to: "PERFORMANCE THRESHOLD EXCEEDED",
                capability: cap
            )
            lines.append(header)
            lines.append("  Test:     \(qualifiedName)")
            lines.append("  Metric:   \(metric)")
            guard let threshold else {
                preconditionFailure("an exceedance factor implies a configured threshold")
            }
            lines.append("  Expected: < \(threshold.formatted(durationFormat))")
            lines.append("  Actual:   \(metric.extract(from: m).formatted(durationFormat))")
            let factorStr =
                "\(factor.formatted(Formatter::Formatter.Number(fractionDigits: 2)))x threshold"
            lines.append("  Factor:   \(Console.Style.error.apply(to: factorStr, capability: cap))")
        } else {
            let header = Console.Style.success.apply(
                to: "PERFORMANCE MEASUREMENT",
                capability: cap
            )
            lines.append(header)
            lines.append("  Test:     \(qualifiedName)")
            lines.append("  Metric:   \(metric)")
            lines.append("  Value:    \(metric.extract(from: m).formatted(durationFormat))")
        }

        lines.append("")
        lines.append("  Distribution:")
        lines.append(
            "    Median: \(m.median.formatted(durationFormat))  Mean: \(m.mean.formatted(durationFormat))  StdDev: \(m.standardDeviation.formatted(durationFormat))"
        )

        if let cv = coefficientOfVariation {
            let cvStr = "\(cv.formatted(Formatter::Formatter.Number(fractionDigits: 2)))%"
            let label: Swift.String
            if cv <= 5.0 {
                label = Console.Style.success.apply(
                    to: "STABLE - result is trustworthy",
                    capability: cap
                )
            } else if cv <= 10.0 {
                label = Console.Style.warning.apply(
                    to: "MODERATE - consider more iterations",
                    capability: cap
                )
            } else {
                label = Console.Style.error.apply(
                    to: "NOISY - result may be unreliable",
                    capability: cap
                )
            }
            lines.append("    CV:     \(cvStr) (\(label))")
        }

        lines.append(
            "    Min:    \(m.min.formatted(durationFormat))  Max: \(m.max.formatted(durationFormat))"
        )
        lines.append(
            "    p95:    \(m.p95.formatted(durationFormat))  p99: \(m.p99.formatted(durationFormat))"
        )

        if let mad = medianAbsoluteDeviation {
            let outlierStr = outlierCount.map { "\($0) of \(m.durations.count)" } ?? "?"
            lines.append("    MAD:    \(mad.formatted(durationFormat))   Outliers: \(outlierStr)")
        }

        lines.append("")
        lines.append("  Trend:")
        let zStr = trend.z.formatted(Formatter::Formatter.Number(fractionDigits: 2))
        let trendLabel: Swift.String
        if trend.interpretation == .increasing {
            trendLabel = Console.Style.error.apply(
                to: "INCREASING - possible thermal throttle",
                capability: cap
            )
        } else if trend.interpretation == .decreasing {
            trendLabel = Console.Style.warning.apply(
                to: "DECREASING - possible caching/warmup effect",
                capability: cap
            )
        } else {
            trendLabel = "NO TREND - not thermal throttle"
        }
        lines.append("    Mann-Kendall Z: \(zStr) (\(trendLabel))")

        if let comparison {
            lines.append("")
            lines.append("  Baseline Comparison:")
            lines.append("    Baseline: \(comparison.baselineValue.formatted(durationFormat))")
            lines.append("    Current:  \(comparison.currentValue.formatted(durationFormat))")
            let changePercent = (comparison.change * 100.0).formatted(
                Formatter::Formatter.Number(fractionDigits: 2)
            )
            if comparison.isRegression {
                let label = Console.Style.error.apply(
                    to: "REGRESSION +\(changePercent)%",
                    capability: cap
                )
                lines.append("    Change:   \(label)")
            } else if comparison.isImprovement {
                let label = Console.Style.success.apply(
                    to: "IMPROVEMENT \(changePercent)%",
                    capability: cap
                )
                lines.append("    Change:   \(label)")
            } else {
                lines.append("    Change:   NO CHANGE")
            }
        } else if baseline == nil, comparison == nil {
        }

        if let history = historyAnalysis {
            lines.append("")
            lines.append("  History (\(history.recordCount) runs):")
            let historyZStr = history.trend.z.formatted(
                Formatter::Formatter.Number(fractionDigits: 2)
            )
            let historyTrendLabel: Swift.String
            if history.trend.interpretation == .increasing {
                historyTrendLabel = Console.Style.error.apply(
                    to: "DEGRADING over time",
                    capability: cap
                )
            } else if history.trend.interpretation == .decreasing {
                historyTrendLabel = Console.Style.success.apply(
                    to: "IMPROVING over time",
                    capability: cap
                )
            } else {
                historyTrendLabel = "STABLE across runs"
            }
            lines.append("    Cross-run Z:  \(historyZStr) (\(historyTrendLabel))")
            lines.append("    Earliest:     \(history.earliestValue.formatted(durationFormat))")
            lines.append("    Latest:       \(history.latestValue.formatted(durationFormat))")
            let changePercent = (history.overallChange * 100.0).formatted(
                Formatter::Formatter.Number(fractionDigits: 2)
            )
            lines.append("    Overall:      \(changePercent)%")
        }

        lines.append("")
        lines.append("  Environment:")
        lines.append("    Architecture:  \(environment.architecture)")
        lines.append(
            "    CPU Cores:     \(environment.physicalCPUCount) (physical) / \(environment.logicalCPUCount) (logical)"
        )
        let memGB = Double(environment.memoryBytes.rawValue) / (1024.0 * 1024.0 * 1024.0)
        lines.append("    Memory:        \(Int(memGB.rounded())) GB")
        lines.append("    Swift:         \(environment.swiftVersion)")
        lines.append("    Optimization:  \(environment.optimization.rawValue)")

        var flagParts: [Swift.String] = []
        if environment.features.nonisolatedNonsendingByDefault {
            flagParts.append("NonisolatedNonsendingByDefault=true")
        }
        if environment.features.strictMemorySafety {
            flagParts.append("StrictMemorySafety=true")
        }
        if flagParts.isEmpty {
            flagParts.append("none")
        }
        lines.append("    Feature Flags: \(flagParts.joined(separator: ", "))")
        lines.append("    OS:            \(environment.osVersion)")

        return lines.joined(separator: "\n")
    }

    /// Structured JSON block delimited for AI agent parsing.
    ///
    /// Emits JSON between `<!-- PERFORMANCE_DIAGNOSTIC_BEGIN -->` and
    /// `<!-- PERFORMANCE_DIAGNOSTIC_END -->` markers. AI agents can extract
    /// this block via simple string search without regex.
    public func jsonBlock() -> Swift.String {
        let m = measurement
        let metricValue = metric.extract(from: m)

        var json: [Swift.String] = []
        json.append("<!-- PERFORMANCE_DIAGNOSTIC_BEGIN -->")
        json.append("{")
        json.append("  \"test\": \(_jsonString(testName)),")
        if let suiteName {
            json.append("  \"suite\": \(_jsonString(suiteName)),")
        }
        json.append("  \"qualified_name\": \(_jsonString(qualifiedName)),")
        json.append(
            "  \"status\": \(exceedanceFactor != nil ? "\"THRESHOLD_EXCEEDED\"" : "\"PASS\""),"
        )
        json.append("  \"metric\": \(_jsonString("\(metric)")),")

        if let t = threshold {
            json.append("  \"threshold\": \(t.inSeconds),")
        }
        json.append("  \"actual\": \(metricValue.inSeconds),")

        if let factor = exceedanceFactor {
            json.append(
                "  \"factor\": \(factor.formatted(Formatter::Formatter.Number(fractionDigits: 2))),"
            )
        }

        json.append("  \"distribution\": {")
        json.append("    \"count\": \(m.durations.count),")
        json.append("    \"min\": \(m.min.inSeconds),")
        json.append("    \"median\": \(m.median.inSeconds),")
        json.append("    \"mean\": \(m.mean.inSeconds),")
        json.append("    \"max\": \(m.max.inSeconds),")
        json.append("    \"stddev\": \(m.standardDeviation.inSeconds),")
        if let cv = coefficientOfVariation {
            json.append(
                "    \"cv\": \(cv.formatted(Formatter::Formatter.Number(fractionDigits: 2))),"
            )
        }
        if let mad = medianAbsoluteDeviation {
            json.append("    \"mad\": \(mad.inSeconds),")
        }
        json.append("    \"p95\": \(m.p95.inSeconds),")
        json.append("    \"p99\": \(m.p99.inSeconds),")
        if let outliers = outlierCount {
            json.append("    \"outliers\": \(outliers)")
        } else {
            json.append("    \"outliers\": null")
        }
        json.append("  },")

        json.append("  \"trend\": {")
        json.append(
            "    \"mann_kendall_z\": \(trend.z.formatted(Formatter::Formatter.Number(fractionDigits: 2))),"
        )
        json.append("    \"interpretation\": \(_jsonString(trend.interpretation.rawValue))")
        json.append("  },")

        json.append("  \"environment\": {")
        json.append("    \"arch\": \(_jsonString(environment.architecture)),")
        json.append("    \"physical_cores\": \(environment.physicalCPUCount),")
        json.append("    \"logical_cores\": \(environment.logicalCPUCount),")
        json.append("    \"memory_bytes\": \(environment.memoryBytes),")
        json.append("    \"swift_version\": \(_jsonString(environment.swiftVersion)),")
        json.append("    \"optimization\": \(_jsonString(environment.optimization.rawValue)),")
        json.append("    \"feature_flags\": {")
        json.append(
            "      \"NonisolatedNonsendingByDefault\": \(environment.features.nonisolatedNonsendingByDefault),"
        )
        json.append("      \"StrictMemorySafety\": \(environment.features.strictMemorySafety)")
        json.append("    },")
        json.append("    \"os\": \(_jsonString(environment.osVersion))")
        json.append("  },")

        if let comparison {
            json.append("  \"baseline\": {")
            json.append("    \"value\": \(comparison.baselineValue.inSeconds),")
            json.append(
                "    \"change\": \(comparison.change.formatted(Formatter::Formatter.Number(fractionDigits: 4))),"
            )
            json.append("    \"is_regression\": \(comparison.isRegression)")
            json.append("  },")
        }

        if let history = historyAnalysis {
            json.append("  \"history\": {")
            json.append("    \"record_count\": \(history.recordCount),")
            json.append(
                "    \"mann_kendall_z\": \(history.trend.z.formatted(Formatter::Formatter.Number(fractionDigits: 2))),"
            )
            json.append(
                "    \"interpretation\": \(_jsonString(history.trend.interpretation.rawValue)),"
            )
            json.append("    \"earliest_s\": \(history.earliestValue.inSeconds),")
            json.append("    \"latest_s\": \(history.latestValue.inSeconds),")
            json.append(
                "    \"overall_change\": \(history.overallChange.formatted(Formatter::Formatter.Number(fractionDigits: 4)))"
            )
            json.append("  },")
        }

        let durationsStr = m.durations.map {
            "\($0.inSeconds.formatted(Formatter::Formatter.Number(fractionDigits: 6)))"
        }
        .joined(separator: ", ")
        json.append("  \"durations_seconds\": [\(durationsStr)]")

        json.append("}")
        json.append("<!-- PERFORMANCE_DIAGNOSTIC_END -->")

        return json.joined(separator: "\n")
    }

    /// Simple JSON string escaping without Foundation.
    private func _jsonString(_ s: Swift.String) -> Swift.String {
        var result = "\""
        for c in s {
            switch c {
            case "\\": result += "\\\\"
            case "\"": result += "\\\""
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            default: result.append(c)
            }
        }
        result += "\""
        return result
    }
}

extension Tests.Diagnostic {
    /// Prints a summary comparison table from an array of diagnostics.
    ///
    /// The table is sorted by qualified name and shows median and min
    /// for each test. When called after all `.timed()` tests complete,
    /// this provides a single view of all performance results.
    public static func summary(_ diagnostics: [Tests.Diagnostic]) {
        guard !diagnostics.isEmpty else { return }

        let sorted = diagnostics.sorted { $0.qualifiedName < $1.qualifiedName }
        let cap = Tests.consoleCapability
        let format = Formatter::Formatter.Duration(
            numeric: Formatter::Formatter.Number(fractionDigits: 3)
        )

        let displayNames = _stripCommonPrefix(sorted.map(\.qualifiedName))

        let nameWidth = max(
            displayNames.map(\.count).max() ?? 0,
            4
        )

        let header = Console.Style.bold.apply(to: "PERFORMANCE SUMMARY", capability: cap)
        print("\n\(header)")
        print("")

        let nameHeader = _pad("Test", to: nameWidth)
        print("| \(nameHeader) |     Median |        Min |")
        print("|\(_line(nameWidth))|------------|------------|")

        for (diagnostic, displayName) in zip(sorted, displayNames) {
            let m = diagnostic.measurement
            let name = _pad(displayName, to: nameWidth)
            let median = _right(m.median.formatted(format), width: 10)
            let min = _right(m.min.formatted(format), width: 10)
            print("| \(name) | \(median) | \(min) |")
        }

        print("")
    }

    private static func _pad(_ s: Swift.String, to width: Int) -> Swift.String {
        if s.count >= width { return s }
        return s + Swift.String(repeating: " ", count: width - s.count)
    }

    private static func _right(_ s: Swift.String, width: Int) -> Swift.String {
        if s.count >= width { return s }
        return Swift.String(repeating: " ", count: width - s.count) + s
    }

    private static func _line(_ width: Int) -> Swift.String {
        Swift.String(repeating: "-", count: width + 2)
    }

    /// Strips the longest common dot-separated prefix from all names.
    ///
    /// `["M.A._10", "M.A._20", "M.B._10"]` → `["A._10", "A._20", "B._10"]`
    private static func _stripCommonPrefix(_ names: [Swift.String]) -> [Swift.String] {
        guard let first = names.first else { return names }
        let parts = first.split(separator: ".")
        var shared = 0
        for i in 0..<parts.count {
            let prefix = parts[0...i].joined(separator: ".")
            let dotPrefix = prefix + "."
            guard names.allSatisfy({ $0.hasPrefix(dotPrefix) }) else {
                break
            }
            shared = i + 1
        }
        guard shared > 0 else { return names }
        let dropLength = parts[0..<shared].joined(separator: ".").count + 1
        return names.map { Swift.String($0.dropFirst(dropLength)) }
    }
}
