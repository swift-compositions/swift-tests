import JSON
import Testing
import Tests_Test_Support

extension Test::Test.Environment.Test {
    @Suite struct JSON {}
}

// MARK: - JSON

extension Test::Test.Environment.Test.JSON {
    @Test
    func `serialize and deserialize preserves all fields`() throws {
        // `Test` here names this suite's enclosing Suite (see Test.Environment
        // Tests.swift), which shadows the top-level `Test.Test`
        // namespace, so the source type must be qualified from the module root.
        let original = Test::Test.Environment.capture()

        let json = Test::Test.Environment.serialize(original)
        let roundtripped = try Test::Test.Environment.deserialize(json)

        #expect(roundtripped.architecture == original.architecture)
        #expect(roundtripped.physicalCPUCount == original.physicalCPUCount)
        #expect(roundtripped.logicalCPUCount == original.logicalCPUCount)
        #expect(roundtripped.memoryBytes == original.memoryBytes)
        #expect(roundtripped.osVersion == original.osVersion)
        #expect(roundtripped.swiftVersion == original.swiftVersion)
        #expect(roundtripped.optimization.rawValue == original.optimization.rawValue)
        #expect(roundtripped.fingerprint == original.fingerprint)
    }

    @Test
    func `features roundtrip correctly`() throws {
        let original = Test::Test.Environment.capture()

        let json = Test::Test.Environment.serialize(original)
        let roundtripped = try Test::Test.Environment.deserialize(json)

        #expect(
            roundtripped.features.nonisolatedNonsendingByDefault
                == original.features.nonisolatedNonsendingByDefault
        )
        #expect(
            roundtripped.features.strictMemorySafety
                == original.features.strictMemorySafety
        )
    }

    @Test
    func `missing required key throws error`() {
        let incomplete: JSON = .object([
            ("architecture", .string("arm64"))
        ])
        #expect(throws: JSON.Error.self) {
            _ = try Test::Test.Environment.deserialize(incomplete)
        }
    }
}
