extension Test.Trait.Scope.Provider {
    /// Scope provider for time limit enforcement.
    public static var timeLimit: Self {
        Self(
            id: "timeLimit",
            priority: 100,
            shouldActivate: { $0[Test.Trait.TimeLimit.self] != nil },
            provideScope: _timeLimitScope
        )
    }

    /// Scope provider for mutual exclusion.
    public static var exclusive: Self {
        Self(
            id: "exclusive",
            priority: 200,
            shouldActivate: { $0[Test.Trait.Exclusive.self] != nil },
            provideScope: _exclusiveScope
        )
    }
}

extension Test.Trait.Scope.Provider {
    @Sendable
    private static func _timeLimitScope(
        _ entry: Test.Plan.Entry,
        _ traits: Test.Trait.Collection,
        _ operation: @Sendable () async throws(Error) -> Void
    ) async throws(Error) {
        guard let limit = traits[Test.Trait.TimeLimit.self] else {
            preconditionFailure("the time-limit scope runs only for entries carrying the trait")
        }
        // WHY: `rethrows` cannot be narrowed to `throws(Error)` by the
        //   compiler, so the untyped rethrow is re-narrowed at the catch.
        // WHEN TO REMOVE: When rethrows supports typed throw inference.
        // TRACKING: upstream Swift gap — rethrows to typed-throws inference.
        do {
            try await withoutActuallyEscaping(operation) { escapingOp in
                try await _withTimeout(limit, operation: escapingOp)
            }
        } catch let error as Self.Error {
            throw error
        } catch {
            throw Error.bodyFailed(
                .caught(
                    type: Swift.String(describing: type(of: error)),
                    description: Swift.String(describing: error)
                )
            )
        }
    }

    @Sendable
    private static func _exclusiveScope(
        _ entry: Test.Plan.Entry,
        _ traits: Test.Trait.Collection,
        _ operation: @Sendable () async throws(Error) -> Void
    ) async throws(Error) {
        guard let exclusive = traits[Test.Trait.Exclusive.self] else {
            preconditionFailure("the exclusive scope runs only for entries carrying the trait")
        }
        let group = exclusive.group
        try await Test.Exclusion.Controller.shared.withExclusiveAccess(
            group: group,
            operation
        )
    }
}

extension Test.Trait.Scope.Provider {
    /// Sentinel error for timeout detection inside `withThrowingTaskGroup`.
    ///
    /// `withThrowingTaskGroup` uses untyped throws, so we throw this private
    /// sentinel and catch it at the task group boundary, converting to the
    /// typed `.timeLimitExceeded` case.
    private struct _Timeout: Swift.Error {
        let limit: Duration
    }

    // WHY: addTask requires `@escaping`; @Sendable closure parameters are
    //   non-escaping, so callers must launder via withoutActuallyEscaping.
    // WHEN TO REMOVE: When Swift supports @escaping on closure parameters
    // in @Sendable function types.
    // TRACKING: upstream Swift gap — @escaping on @Sendable closure params.
    /// Runs an operation with a timeout.
    ///
    /// - Note: `withThrowingTaskGroup` erases typed throws. The catch
    ///   boundary here converts between untyped task group errors and
    ///   our typed `Error` enum.
    @Sendable
    private static func _withTimeout(
        _ timeout: Duration,
        operation: @escaping @Sendable () async throws(Error) -> Void
    ) async throws(Error) {
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await operation()
                }
                group.addTask {
                    try await Task.sleep(for: timeout)
                    throw _Timeout(limit: timeout)
                }
                try await group.next()
                group.cancelAll()
            }
        } catch let error as Self.Error {
            throw error
        } catch let error as _Timeout {
            throw .timeLimitExceeded(limit: error.limit)
        } catch {
            throw .bodyFailed(
                .caught(
                    type: Swift.String(describing: type(of: error)),
                    description: Swift.String(describing: error)
                )
            )
        }
    }
}
