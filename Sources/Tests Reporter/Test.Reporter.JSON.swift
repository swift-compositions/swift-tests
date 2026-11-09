import JSON
import Kernel
public import Path
import Synchronization
import Test

extension Test.Reporter {
    /// Creates a JSON reporter.
    ///
    /// - Parameter path: File path for output, or nil for stdout.
    /// - Returns: A reporter that outputs JSON.
    public static func json(to path: Path::Path? = nil) -> Test.Reporter {
        Test.Reporter {
            Sink(JSONSink(outputPath: path?.string))
        }
    }
}

extension Test.Reporter {
    /// A test reporter sink that outputs JSON with thread-safe event collection.
    ///
    /// Serializes with swift-json, as the structured reporter does, so strings are escaped.
    ///
    /// ## Safety Invariant
    ///
    /// Mutable `_events` is guarded by `Mutex<[Test.Event]>`. All mutation
    /// via `_events.withLock`. The `outputPath` is set once at init.
    ///
    /// ## Intended Use
    ///
    /// - JSON test event capture for CI tools, stdout, or file output.
    ///
    /// ## Non-Goals
    ///
    /// - NOT for streaming; events are collected and emitted in batch at `finish()`.
    private final class JSONSink: Sink.Implementation, @unsafe @unchecked Sendable {
        let outputPath: Swift.String?
        private let _events = Mutex<[Test.Event]>([])

        init(outputPath: Swift.String?) {
            self.outputPath = outputPath
        }

        func send(_ event: Test.Event) async {
            _events.withLock { $0.append(event) }
        }

        func finish() async {
            let events = _events.withLock { $0 }
            let bytes = Array((Test.Reporter.jsonDocument(for: events).serialize(pretty: true) + "\n").utf8)

            if let path = outputPath {
                write(to: path, bytes: bytes)
            } else {
                write(stdout: bytes)
            }
        }

        private func write(to path: Swift.String, bytes: [UInt8]) {
            do {
                let descriptor = try Path.scope(path) { pathView in
                    try Kernel.File.Open.open(
                        path: pathView,
                        mode: .write,
                        options: [.create, .truncate],
                        permissions: .standard
                    )
                }
                var remaining = bytes[...]
                while !remaining.isEmpty {
                    let written = try remaining.withUnsafeBytes { buffer in
                        try unsafe Kernel.IO.Write.write(descriptor, from: buffer)
                    }
                    remaining = remaining.dropFirst(written)
                }
            } catch {
            }
        }

        private func write(stdout bytes: [UInt8]) {
            print(Swift.String(decoding: bytes, as: UTF8.self), terminator: "")
        }
    }
}

extension Test.Reporter {
    /// The document the JSON reporter writes: `{"events": [...]}`, one object per event.
    static func jsonDocument(for events: [Test.Event]) -> JSON {
        .object([("events", .array(events.map { jsonRecord(for: $0) }))])
    }

    static func jsonRecord(for event: Test.Event) -> JSON {
        var fields: [(Swift.String, JSON)] = [("kind", .string(event.kind.underlying))]

        if let id = event.id {
            fields.append(("test_id", .string(id.fullyQualifiedName)))
        }

        if let result = event.result {
            fields.append(("result", .string("\(result)")))
        }

        if let duration = event.elapsed {
            let components = duration.components
            let nanoseconds =
                Swift.Int(components.seconds) * 1_000_000_000
                + Swift.Int(components.attoseconds / 1_000_000_000)
            fields.append(("elapsed_ns", .number(nanoseconds)))
        }

        return .object(fields)
    }
}
