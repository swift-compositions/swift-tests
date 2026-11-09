extension Test.Trait {
    /// Witness key for snapshot configuration.
    public struct Snapshot: Sendable {
        /// The snapshot configuration the scope installs.
        public let configuration: Test.Snapshot.Configuration

        /// Creates a snapshot value carrying a whole configuration.
        public init(configuration: Test.Snapshot.Configuration) {
            self.configuration = configuration
        }

        /// Creates a snapshot value that sets only the recording mode.
        public init(recording: Test.Snapshot.Recording) {
            self.init(configuration: .init(recording: recording))
        }
    }
}

extension Test.Trait.Snapshot: Witness.Key {
    public typealias Value = Test.Trait.Snapshot?

    @inlinable
    public static var liveValue: Test.Trait.Snapshot? { nil }
}

extension Test.Trait.Collection {
    /// The snapshot recording mode, if set.
    public var snapshotRecording: Test.Snapshot.Recording? {
        get { self[Test.Trait.Snapshot.self]?.recording }
        set {
            if let newValue {
                self[Test.Trait.Snapshot.self] = Test.Trait.Snapshot(recording: newValue)
            } else {
                self[Test.Trait.Snapshot.self] = nil
            }
        }
    }
}

extension Test.Trait.Snapshot {
    /// The recording mode for snapshots.
    public var recording: Test.Snapshot.Recording {
        configuration.recording
    }
}
