#if canImport(Testing)
    public import Test
    public import Testing
    import Dependency

    extension Test::Test.Snapshot.Recording {
        /// Swift Testing trait that sets the snapshot recording mode for a suite or test.
        ///
        /// ## Usage
        ///
        /// ```swift
        /// @Suite(.snapshots(record: .all))
        /// struct MySnapshotTests {
        ///     @Test func mySnapshot() {
        ///         assertInlineSnapshot(of: value, as: .lines)
        ///     }
        /// }
        /// ```
        public struct Trait: Testing.SuiteTrait, Testing.TestTrait, Sendable {
            /// The recording mode to apply within this scope.
            public let recording: Test::Test.Snapshot.Recording
        }
    }

    extension Test::Test.Snapshot.Recording.Trait {
        /// Propagate to all nested tests and suites.
        public var isRecursive: Bool { true }
    }

    extension Test::Test.Snapshot.Recording.Trait: Testing.TestScoping {
        @concurrent
        public func provideScope(
            for test: Testing.Test,
            testCase: Testing.Test.Case?,
            performing function: @Sendable @concurrent () async throws -> Void
        ) async throws {
            let config = Test::Test.Snapshot.Configuration(recording: recording)
            try await Dependency.Scope.with(
                { $0[Test::Test.Snapshot.Configuration.Key.self] = config },
                operation: function
            )
        }
    }

    extension Testing.Trait where Self == Test::Test.Snapshot.Recording.Trait {
        /// Sets the snapshot recording mode for a suite or test.
        ///
        /// - Parameter recording: The recording mode to use.
        /// - Returns: A trait that configures snapshot recording.
        public static func snapshots(
            record recording: Test::Test.Snapshot.Recording
        ) -> Self {
            Test::Test.Snapshot.Recording.Trait(recording: recording)
        }
    }
#endif
