public import Sample

extension Test.Trait.Collection {
    /// A closure that sets witness values on a trait collection.
    ///
    /// Modifiers are the transport mechanism for trait declarations.
    /// Each modifier encapsulates the effect of a single trait
    /// (e.g., `.serialized` sets `Serialized.self = true`,
    /// `.timeLimit(.seconds(30))` sets `TimeLimit.self = .seconds(30)`).
    ///
    /// Factory methods on this type mirror the existing `Test.Trait`
    /// factories, providing identical names and parameters.
    public struct Modifier: Sendable {
        /// The closure that mutates the collection.
        internal let _apply: @Sendable (inout Test.Trait.Collection) -> Void

        // swiftlint:disable typed_throws_required
        /// Optional scope provider for Apple Testing integration.
        ///
        /// When present, the `TestScoping` conformance (in the Apple Testing Bridge)
        /// delegates to this closure to inject dependency scope. When absent,
        /// `provideScope` passes through without wrapping.
        package let _provideScope:
            (
                @Sendable @concurrent (
                    @Sendable @concurrent () async throws -> Void
                ) async throws -> Void
            )?

        /// Creates a modifier from a mutation closure.
        ///
        /// - Parameter apply: A closure that sets witness values on the collection.
        public init(_ apply: @escaping @Sendable (inout Test.Trait.Collection) -> Void) {
            self._apply = apply
            self._provideScope = nil
        }

        /// Creates a modifier with both a mutation closure and a scope provider.
        ///
        /// - Parameters:
        ///   - apply: A closure that sets witness values on the collection.
        ///   - provideScope: A closure that wraps test execution with dependency scope.
        package init(
            apply: @escaping @Sendable (inout Test.Trait.Collection) -> Void,
            provideScope:
                @escaping @Sendable @concurrent (
                    @Sendable @concurrent () async throws -> Void
                ) async throws -> Void
        ) {
            self._apply = apply
            self._provideScope = provideScope
        }
        // swiftlint:enable typed_throws_required
    }
}

extension Test.Trait.Collection.Modifier {
    /// Applies this modifier to the given collection.
    ///
    /// - Parameter collection: The collection to mutate.
    public func apply(to collection: inout Test.Trait.Collection) {
        _apply(&collection)
    }
}

extension Test.Trait.Collection.Modifier {
    /// Sets a time limit for test execution.
    ///
    /// - Parameter duration: The maximum duration for the test.
    public static func timeLimit(_ duration: Duration) -> Self {
        Self { $0[Test.Trait.TimeLimit.self] = duration }
    }

    /// Adds a tag for filtering and categorization.
    ///
    /// - Parameter name: The tag name.
    public static func tag(_ name: Swift.String) -> Self {
        Self { collection in
            var tags = collection[Test.Trait.Tag.self]
            tags.insert(name)
            collection[Test.Trait.Tag.self] = tags
        }
    }

    /// Sets an enabled condition.
    ///
    /// - Parameters:
    ///   - condition: Whether the test should run.
    ///   - comment: Explanation for why the test is disabled.
    public static func enabled(if condition: Bool, _ comment: Test.Text? = nil) -> Self {
        Self { $0[Test.Trait.Enabled.self] = .init(isEnabled: condition, comment: comment) }
    }

    /// Disables the test.
    ///
    /// - Parameter comment: Explanation for why the test is disabled.
    public static func disabled(_ comment: Test.Text? = nil) -> Self {
        Self { $0[Test.Trait.Enabled.self] = .init(isEnabled: false, comment: comment) }
    }

    /// Adds a bug reference.
    ///
    /// - Parameters:
    ///   - id: The bug identifier.
    ///   - comment: Additional context.
    public static func bug(_ id: Swift.String, _ comment: Test.Text? = nil) -> Self {
        Self { $0[Test.Trait.Bug.self] = .init(id: id, comment: comment) }
    }

    /// Marks the test for serial execution (not in parallel).
    public static var serialized: Self {
        Self { $0[Test.Trait.Serialized.self] = true }
    }

    /// Marks the test for mutual exclusion within the global group.
    public static var exclusive: Self {
        exclusive(group: Test.Trait.Exclusive.globalGroup)
    }

    /// Marks the test for mutual exclusion within a specific group.
    ///
    /// - Parameter group: The exclusion group name.
    public static func exclusive(group: Swift.String) -> Self {
        Self { $0[Test.Trait.Exclusive.self] = .init(group: group) }
    }

    /// Configures timed benchmark execution.
    ///
    /// - Parameters:
    ///   - iterations: Number of measurement runs (default: 10).
    ///   - warmup: Number of untimed warmup runs (default: 0).
    ///   - threshold: Optional performance budget.
    ///   - metric: Metric to check against threshold (default: .median).
    ///   - trackAllocations: Whether to track memory allocations per iteration (default: false).
    ///   - baselineTolerance: Optional tolerance for baseline regression detection
    ///     (e.g., `0.10` = 10%). When set, baselines are loaded, compared, and
    ///     saved automatically.
    public static func timed(
        iterations: Int = 10,
        warmup: Int = 0,
        threshold: Duration? = nil,
        metric: Test.Benchmark.Metric = .median,
        trackAllocations: Bool = false,
        baselineTolerance: Double? = nil
    ) -> Self {
        Self {
            $0[Test.Trait.Timed.self] = .init(
                iteration: .init(count: iterations, warmup: warmup),
                evaluation: .init(
                    threshold: threshold,
                    metric: metric,
                    baselineTolerance: baselineTolerance,
                    trackAllocations: trackAllocations
                )
            )
        }
    }
}
