#if canImport(Testing)
    public import Testing
    public import Test

    extension Test::Test.Trait.Collection.Modifier:
        Testing.SuiteTrait, Testing.TestScoping
    {
        public var isRecursive: Bool { true }

        @concurrent
        public func provideScope(
            for test: Testing.Test,
            testCase: Testing.Test.Case?,
            performing function: @Sendable @concurrent () async throws -> Void
        ) async throws {
            if let provideScope = _provideScope {
                try await provideScope(function)
            } else {
                try await function()
            }
        }
    }
#endif
