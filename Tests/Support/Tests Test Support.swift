public import Source
import Synchronization
public import Test
public import Tests

// MARK: - Test.Benchmark.Measurement Factory

extension Test::Test.Benchmark.Measurement {
    /// Creates a measurement from millisecond integer values.
    ///
    /// Simplifies test data construction:
    /// ```swift
    /// let measurement = Test.Benchmark.Measurement.with([10, 20, 30, 40, 50])
    /// #expect(measurement.median == .milliseconds(30))
    /// ```
    public static func with(_ milliseconds: [Int]) -> Self {
        Self(durations: milliseconds.map { .milliseconds($0) })
    }
}

// MARK: - Test.Plan.Entry Factory

extension Tests_Core.Test.Plan.Entry {
    /// Creates a plan entry with sensible defaults.
    ///
    /// ```swift
    /// let entry = Test.Plan.Entry.stub("myTest")
    /// ```
    public static func stub(
        _ name: Swift.String,
        module: Swift.String = "TestModule",
        modifiers: [Tests_Core.Test.Trait.Collection.Modifier] = [],
        body: Tests_Core.Test.Body = .sync {}
    ) -> Self {
        .init(
            id: .stub(name, module: module),
            modifiers: modifiers,
            body: body
        )
    }
}

// MARK: - Spy Sink

/// A sink that captures all events for test assertions.
public final class SpySink: Tests_Core.Test.Reporter.Sink.Implementation, @unchecked Sendable {
    private let _events = Mutex<[Test::Test.Event]>([])

    public init() {}
}

extension SpySink {
    public var events: [Test::Test.Event] {
        _events.withLock { $0 }
    }

    public func send(_ event: Test::Test.Event) async {
        _events.withLock { $0.append(event) }
    }

    public func finish() async {}
}

// MARK: - Spy Reporter

/// Creates a reporter + spy pair for test assertions.
public enum SpyReporter {}

extension SpyReporter {
    public static func make() -> (Tests_Core.Test.Reporter, SpySink) {
        let spy = SpySink()
        let reporter = Tests_Core.Test.Reporter {
            Tests_Core.Test.Reporter.Sink(spy)
        }
        return (reporter, spy)
    }
}

extension Tests_Core.Test.ID {
    public static func stub(
        _ name: Swift.String,
        module: Swift.String = "TestModule",
        suite: Swift.String? = nil
    ) -> Self {
        .init(
            module: module,
            suite: suite,
            name: name,
            sourceLocation: Source.Location(fileID: "\(module)/Stub.swift", line: 1, column: 1)
        )
    }
}

extension Source.Location {
    public static func stub(line: Int = 1, column: Int = 1) -> Self {
        .init(fileID: "TestModule/Stub.swift", line: line, column: column)
    }
}
