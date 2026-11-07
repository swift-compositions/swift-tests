import Test

extension Tagged where Tag == Test.Event, Underlying == Swift.String {

    /// Structured plan record with git, environment, and test list.
    public static var planRecord: Self { Self(_unchecked: "planRecord") }

    /// Structured summary record with counts and failures.
    public static var summaryRecord: Self { Self(_unchecked: "summaryRecord") }

    /// A single performance diagnostic from a `.timed()` test.
    public static var performanceDiagnostic: Self { Self(_unchecked: "performanceDiagnostic") }

    /// A complexity analysis diagnostic.
    public static var complexityDiagnostic: Self { Self(_unchecked: "complexityDiagnostic") }

    /// Summary table across all performance tests in the run.
    public static var performanceSummary: Self { Self(_unchecked: "performanceSummary") }
}
