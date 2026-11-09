import File_System
import Testing
import Tests_Inline_Snapshot
import Tests_Test_Support

extension Test::Test.Snapshot {
    @Suite
    struct Test {
        @Suite struct Unit {}
    }
}

// MARK: - Unit

extension Test::Test.Snapshot.Test.Unit {

    @Test
    func `HTML strategy renders a document through snapshot`() {
        let collector = Test::Test.Expectation.Collector()
        Test::Test.Expectation.Collector.with(collector) {
            snapshot(
                as: .html,
                record: .never,
                {
                    HTML.Document { "Hello" }
                },
                matches: {
                    """
                    <!doctype html>
                    <html>
                      <head>
                      </head>
                      <body>Hello
                      </body>
                    </html>
                    """
                }
            )
        }
        let expectations = collector.drain()
        #expect(expectations.count == 1)
        if expectations.count == 1 {
            #expect(expectations[0].isPassing)
        }
    }

    @Test
    func `snapshot registers passing expectation with collector`() {
        let collector = Test::Test.Expectation.Collector()
        Test::Test.Expectation.Collector.with(collector) {
            // .missing mode: no reference exists → records to /tmp/ → passes
            snapshot(
                as: .lines,
                named: "passing",
                record: .missing,
                { "hello" },
                filePath: "/tmp/swift-tests-unit/SnapshotPassingTest.swift",
                function: "passingTest()"
            )
        }
        let expectations = collector.drain()
        #expect(expectations.count == 1)
        if expectations.count == 1 {
            #expect(expectations[0].isPassing)
        }
    }

    @Test
    func `snapshot registers failing expectation with collector`() {
        let collector = Test::Test.Expectation.Collector()
        Test::Test.Expectation.Collector.with(collector) {
            // .never mode: no reference exists → missingReference → fails
            snapshot(
                as: .lines,
                named: "failing",
                record: .never,
                { "hello" },
                filePath: "/tmp/nonexistent-path/SnapshotFailingTest.swift",
                function: "failingTest()"
            )
        }
        let expectations = collector.drain()
        #expect(expectations.count == 1)
        if expectations.count == 1 {
            #expect(expectations[0].isFailing)
        }
    }

    @Test
    func `snapshot registers multiple expectations with collector`() {
        let collector = Test::Test.Expectation.Collector()
        Test::Test.Expectation.Collector.with(collector) {
            // Passes (records new snapshot in /tmp/)
            snapshot(
                as: .lines,
                named: "multi-pass",
                record: .missing,
                { "hello" },
                filePath: "/tmp/swift-tests-unit/SnapshotMultipleTest.swift",
                function: "multipleTest()"
            )
            // Fails (no reference with .never mode)
            snapshot(
                as: .lines,
                named: "multi-fail",
                record: .never,
                { "world" },
                filePath: "/tmp/nonexistent-path/SnapshotMultipleFail.swift",
                function: "multipleFail()"
            )
        }
        let expectations = collector.drain()
        #expect(expectations.count == 2)
        if expectations.count == 2 {
            #expect(expectations[0].isPassing)
            #expect(expectations[1].isFailing)
        }
    }

    @Test
    func `record all passes for an inline snapshot as it does for a file-backed one`() {
        let collector = Test::Test.Expectation.Collector()
        Test::Test.Expectation.Collector.with(collector) {
            snapshot(
                as: .lines,
                record: .all,
                { "hello" },
                matches: { "world" },
                filePath: "/tmp/swift-tests-unit/SnapshotInlineAll.swift",
                function: "inlineAll()"
            )
            snapshot(
                as: .lines,
                named: "record-all",
                record: .all,
                { "hello" },
                filePath: "/tmp/swift-tests-unit/SnapshotFileAll.swift",
                function: "fileAll()"
            )
        }
        let expectations = collector.drain()
        #expect(expectations.count == 2)
        if expectations.count == 2 {
            #expect(expectations[0].isPassing)
            #expect(expectations[1].isPassing)
        }
    }

    @Test
    func `a missing inline snapshot is recorded and passes as a missing file-backed one does`() {
        let collector = Test::Test.Expectation.Collector()
        Test::Test.Expectation.Collector.with(collector) {
            snapshot(
                as: .lines,
                record: .missing,
                { "hello" },
                filePath: "/tmp/swift-tests-unit/SnapshotInlineMissing.swift",
                function: "inlineMissing()"
            )
        }
        let expectations = collector.drain()
        #expect(expectations.count == 1)
        if expectations.count == 1 {
            #expect(expectations[0].isPassing)
        }
    }

    @Test
    func `a non-String file-backed snapshot is stored under the configured subdirectory`() {
        let filePath = "/tmp/swift-tests-unit/SnapshotSubdirectory.swift"
        let subdirectory = File.Path.Component("Configured")
        let collector = Test::Test.Expectation.Collector()
        Test::Test.Expectation.Collector.with(collector) {
            _ = Test::Test.Snapshot.withConfiguration(.init(recording: .all, subdirectory: subdirectory)) {
                snapshot(
                    as: .data,
                    named: "bytes",
                    { [] },
                    filePath: filePath,
                    function: "subdirectory()"
                )
            }
        }
        let expectations = collector.drain()
        #expect(expectations.count == 1)
        if expectations.count == 1 {
            #expect(expectations[0].isPassing)
        }

        let path = Test::Test.Snapshot.Storage.path(
            testFilePath: filePath,
            function: "subdirectory()",
            name: "bytes",
            counter: 0,
            pathExtension: "bin",
            subdirectory: subdirectory
        )
        #expect(Test::Test.Snapshot.Storage.exists(at: path))
    }
}
