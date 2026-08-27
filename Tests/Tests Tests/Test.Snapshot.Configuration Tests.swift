import Testing
import Tests_Test_Support

extension Test.Test.Snapshot.Configuration {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

// MARK: - Unit

extension Test.Test.Snapshot.Configuration.Test.Unit {
    @Test
    func `default uses missing recording mode`() {
        let config = Test.Test.Snapshot.Configuration.default
        #expect(config.recording == .missing)
    }

    @Test
    func `init stores custom values`() {
        let config = Test.Test.Snapshot.Configuration(recording: .all)
        #expect(config.recording == .all)
    }

    @Test
    func `resolve returns explicit when provided`() {
        let result = Test.Test.Snapshot.Configuration.resolve(recording: .all)
        #expect(result == .all)
    }

    @Test
    func `resolve returns missing as default fallback`() {
        let result = Test.Test.Snapshot.Configuration.resolve(recording: nil)
        // Without task-local or env var, falls back to .missing
        #expect(result == .missing)
    }
}

// MARK: - EdgeCase

extension Test.Test.Snapshot.Configuration.Test.`Edge Case` {
    @Test
    func `snapshotDirectory defaults to nil`() {
        let config = Test.Test.Snapshot.Configuration.default
        #expect(config.snapshotDirectory == nil)
    }
}
