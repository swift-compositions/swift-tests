// This source file is part of the swift-test-snapshot open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-test-snapshot project authors
// Licensed under Apache License v2.0

public import Test

extension Test.Snapshot {
    public struct Modifier: Test.Modifier {
        public let configuration: Configuration
        public let inheritance: Test.Scope.Inheritance

        public init(
            configuration: Configuration,
            inheritance: Test.Scope.Inheritance = .recursive
        ) {
            self.configuration = configuration
            self.inheritance = inheritance
        }
    }
}

extension Test.Snapshot.Modifier {
    public func apply<R: ~Copyable, E: Swift.Error>(
        in context: Test.Context,
        isolation: isolated (any Actor)?,
        operation: @isolated(any) () async throws(E) -> sending R
    ) async throws(E) -> sending R {
        try await operation()
    }

    public func scope<E: Swift.Error>(
        in context: Test.Context,
        isolation: isolated (any Actor)?,
        operation: @isolated(any) () async throws(E) -> sending Void
    ) async throws(E) {
        // swift-linter:disable:next do throws for typed catch
        // REASON: TaskLocal.withValue currently exposes untyped rethrows across this boundary.
        do {
            try await Test.Snapshot.Configuration.$current.withValue(configuration) { () async throws(E) in
                try await context.with(isolation: isolation, operation: operation)
            }
        } catch let error as E {
            throw error
        } catch {
            preconditionFailure("TaskLocal.withValue introduced an unexpected error type")
        }
    }
}
