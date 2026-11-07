import Sample
public import Test

extension Tests.Complexity {
    /// Interprets raw complexity evidence under a policy to produce a result.
    ///
    /// Applies constant-time detection, adequacy gates, monotonicity checks,
    /// fit quality thresholds, separation analysis, and cross-validation to
    /// derive a confidence level and best candidate classification.
    ///
    /// All thresholds come from the ``Policy`` and are provisional.
    ///
    /// - Parameters:
    ///   - evidence: Raw analytical evidence from L1 fitting.
    ///   - policy: Classification thresholds and candidate set.
    /// - Returns: An interpreted ``Result`` with confidence and classification.
    public static func classify(
        _ evidence: Test.Benchmark.Complexity.Evidence,
        under policy: Policy = .default
    ) -> Result {
        if policy.constantCVThreshold > 0,
            evidence.monotonicity.interpretation == .none,
            evidence.metricCV < policy.constantCVThreshold,
            evidence.points.count >= policy.minimumSizePoints,
            Self.hasScaleRange(evidence, policy: policy)
        {
            let constantCandidate =
                evidence.candidates
                .first { $0.complexity == .constant }
                ?? Test.Benchmark.Complexity.Candidate.Fit(
                    complexity: .constant,
                    regression: Sample.Regression.Fit(
                        slope: 0,
                        intercept: 0,
                        rSquared: 0,
                        meanSquaredError: 0
                    ),
                    effectiveExponent: 0
                )
            let confidence: Confidence
            if evidence.metricCV < policy.constantCVThreshold * 0.2 {
                confidence = .high
            } else if evidence.metricCV < policy.constantCVThreshold * 0.5 {
                confidence = .medium
            } else {
                confidence = .low
            }
            return Result(
                evidence: evidence,
                best: constantCandidate,
                confidence: confidence,
                ambiguousWith: [],
                reasons: []
            )
        }

        var reasons: [InconclusiveReason] = []

        if evidence.points.count < policy.minimumSizePoints {
            reasons.append(.insufficientData)
        }

        if !Self.hasScaleRange(evidence, policy: policy) {
            reasons.append(.insufficientScaleRange)
        }

        if evidence.monotonicity.interpretation == .none
            || evidence.monotonicity.interpretation == .decreasing
        {
            reasons.append(.nonMonotone)
        }

        if evidence.exponent.fit.rSquared < policy.logLogRSquaredFloor {
            reasons.append(.weakContinuousFit)
        }

        if !reasons.isEmpty {
            return Result(
                evidence: evidence,
                best: nil,
                confidence: .inconclusive,
                ambiguousWith: [],
                reasons: reasons
            )
        }

        let viable = evidence.candidates.filter {
            $0.regression.slope > 0
                && $0.regression.rSquared >= policy.candidateRSquaredFloor
        }

        guard let best = viable.first else {
            return Result(
                evidence: evidence,
                best: nil,
                confidence: .inconclusive,
                ambiguousWith: [],
                reasons: [.noSeparatedWinner]
            )
        }

        let runnerUp = viable.dropFirst().first
        let separation =
            runnerUp.map {
                best.regression.rSquared - $0.regression.rSquared
            } ?? 1.0

        let ambiguous = viable.filter {
            $0.complexity != best.complexity
                && (best.regression.rSquared - $0.regression.rSquared)
                    < policy.mediumSeparationThreshold
        }.map(\.complexity)

        var confidence: Confidence
        if separation >= policy.highSeparationThreshold {
            confidence = .high
        } else if separation >= policy.mediumSeparationThreshold {
            confidence = .medium
        } else {
            confidence = .low
        }

        let tolerance = Swift.max(
            policy.exponentConsistencyTolerance,
            0.3 * Swift.abs(best.effectiveExponent)
        )
        let deviation = Swift.abs(
            evidence.exponent.value - best.effectiveExponent
        )
        if deviation > tolerance {
            switch confidence {
            case .high: confidence = .medium
            case .medium: confidence = .low
            case .low, .inconclusive: break
            }
            reasons.append(.inconsistentSignals)
        }

        return Result(
            evidence: evidence,
            best: best,
            confidence: confidence,
            ambiguousWith: ambiguous,
            reasons: reasons
        )
    }

    private static func hasScaleRange(
        _ evidence: Test.Benchmark.Complexity.Evidence,
        policy: Policy
    ) -> Bool {
        guard let first = evidence.points.first,
            let last = evidence.points.last,
            first.size > 0
        else { return false }
        return Double(last.size) / Double(first.size) >= policy.minimumScaleRange
    }
}
