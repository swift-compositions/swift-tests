extension Test.Trait {
    /// Witness key for time limit configuration.
    public struct TimeLimit: Sendable {}
}

extension Test.Trait.TimeLimit: Witness.Key {
    public typealias Value = Duration?

    @inlinable
    public static var liveValue: Duration? { nil }
}
