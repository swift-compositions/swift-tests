import Testing
import Tests_Test_Support

extension Test::Test.Body {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

// MARK: - Unit

extension Test::Test.Body.Test.Unit {
    @Test
    func `sync factory creates synchronous body`() {
        let body = Test::Test.Body.sync {}
        #expect(body.isSync)
        #expect(!body.isAsync)
    }

    @Test
    func `async factory creates asynchronous body`() {
        let body = Test::Test.Body.async {}
        #expect(body.isAsync)
        #expect(!body.isSync)
    }

    @Test
    func `sync body run succeeds`() async throws {
        let body = Test::Test.Body.sync {}
        do throws(Test::Test.Body.Error) {
            try await body.run()
        } catch {
            Issue.record("Expected sync body to succeed, got: \(error)")
        }
    }

    @Test
    func `async body run succeeds`() async throws {
        let body = Test::Test.Body.async {}
        do throws(Test::Test.Body.Error) {
            try await body.run()
        } catch {
            Issue.record("Expected async body to succeed, got: \(error)")
        }
    }

    @Test
    func `sync body catches thrown error`() async {
        struct TestError: Swift.Error, Swift.CustomStringConvertible {
            var description: Swift.String { "test failure" }
        }

        let body = Test::Test.Body.sync { throw TestError() }
        do throws(Test::Test.Body.Error) {
            try await body.run()
            Issue.record("Expected body.run() to throw")
        } catch {
            if case .caught(let type, let description) = error {
                #expect(type.contains("TestError"))
                #expect(description.contains("test failure"))
            } else {
                Issue.record("Unexpected error case: \(error)")
            }
        }
    }

    @Test
    func `async body catches thrown error`() async {
        struct TestError: Swift.Error, Swift.CustomStringConvertible {
            var description: Swift.String { "async failure" }
        }

        let body = Test::Test.Body.async { throw TestError() }
        do throws(Test::Test.Body.Error) {
            try await body.run()
            Issue.record("Expected body.run() to throw")
        } catch {
            if case .caught(let type, let description) = error {
                #expect(type.contains("TestError"))
                #expect(description.contains("async failure"))
            } else {
                Issue.record("Unexpected error case: \(error)")
            }
        }
    }
}

// MARK: - EdgeCase

extension Test::Test.Body.Test.`Edge Case` {
    @Test
    func `caught error stores type and description`() async {
        struct SpecificError: Swift.Error, Swift.CustomStringConvertible {
            let detail: Swift.String
            var description: Swift.String { "detail: \(detail)" }
        }

        let body = Test::Test.Body.sync { throw SpecificError(detail: "abc123") }
        do throws(Test::Test.Body.Error) {
            try await body.run()
        } catch {
            if case .caught(let type, let description) = error {
                #expect(type == "SpecificError")
                #expect(description.contains("abc123"))
            }
        }
    }
}
