import JSON
import Testing
import Tests_Test_Support

@testable import Tests_Reporter

enum `Test.Reporter.JSON Tests` {}

extension `Test.Reporter.JSON Tests` {
    @Suite
    struct Test {
        @Suite struct Unit {}
    }
}

// MARK: - Unit

extension `Test.Reporter.JSON Tests`.Test.Unit {

    @Test
    func `a test name with quotes and a backslash serializes to valid JSON`() throws {
        let event = Test::Test.Event(
            id: .stub(#"says "hi" \ bye"#),
            kind: .testEnded,
            result: .passed
        )
        let document = Tests_Core.Test.Reporter.jsonDocument(for: [event])
        let text = document.serialize(pretty: true)

        #expect(try JSON.parse(text) == document)
        #expect(text.contains(#"says \"hi\" \\ bye"#))
    }

    @Test
    func `elapsed nanoseconds include whole seconds`() {
        let event = Test::Test.Event(kind: .runEnded, elapsed: .milliseconds(2500))
        let record = Tests_Core.Test.Reporter.jsonRecord(for: event)

        #expect(record.serialize().contains(#""elapsed_ns":2500000000"#))
    }
}
