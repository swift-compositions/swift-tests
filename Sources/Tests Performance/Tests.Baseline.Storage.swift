import Environment
public import File_System
public import IO_Kernel
import JSON
public import Thread_Pool

extension Tests.Baseline {
    /// Handles baseline file I/O.
    ///
    /// Baselines are stored as JSON files in a configurable root directory
    /// (default `.benchmarks/`), organized by test identity and environment
    /// fingerprint.
    ///
    /// ## Directory Convention
    ///
    /// ```
    /// .benchmarks/
    ///   {module}/
    ///     {suite}/                    ← omitted if no suite
    ///       {test-name}/
    ///         {fingerprint}.json      ← e.g., arm64-10c-debug-nnbd-sms.json
    /// ```
    public enum Storage {}
}

extension Tests.Baseline.Storage {
    /// Resolves the baseline root directory.
    ///
    /// Uses the `SWIFT_BENCHMARK_DIR` environment variable if set,
    /// otherwise defaults to `.benchmarks` relative to the current
    /// working directory.
    public static func root() -> File.Path {
        if let value = Environment.read("SWIFT_BENCHMARK_DIR"), !value.isEmpty {
            return File.Path(stringLiteral: value)
        }
        return File.Path(stringLiteral: ".benchmarks")
    }
}

extension Tests.Baseline.Storage {
    /// Computes the baseline file path from test identity and fingerprint.
    ///
    /// - Parameters:
    ///   - root: The baseline root directory.
    ///   - testID: The test identifier providing module, suite, and name.
    ///   - fingerprint: The environment fingerprint for the filename.
    /// - Returns: The computed baseline file path.
    public static func path(
        root: File.Path,
        testID: Test.ID,
        fingerprint: Swift.String
    ) -> File.Path {
        var result = root / File.Path.Component(stringLiteral: "\(testID.module)")

        if let suite = testID.suite {
            for component in suite.split(separator: ".") {
                // swiftlint:disable:next shorthand_operator
                result = result / File.Path.Component(stringLiteral: "\(component)")
            }
        }

        return result / File.Path.Component(stringLiteral: "\(testID.name)") / File.Path.Component(stringLiteral: "\(fingerprint).json")
    }

}

extension Tests.Baseline.Storage {
    /// Loads a stored baseline measurement, or `nil` if no baseline exists.
    ///
    /// - Parameter path: Path to the baseline JSON file.
    /// - Returns: The deserialized measurement, or `nil` if the file does not exist.
    public static func load(at path: File.Path) -> Test.Benchmark.Measurement? {
        let file = File(path)
        guard file.stat.exists else { return nil }

        do {
            return try file.read.full { span in
                let bytes: [Byte] = span.withUnsafeBufferPointer { unsafe .init($0) }
                let json = try JSON.parse(bytes)
                return try Test.Benchmark.Measurement(json: json)
            }
        } catch {
            return nil
        }
    }
}

extension Tests.Baseline.Storage {
    /// Loads a stored baseline measurement, or `nil` if no baseline exists.
    ///
    /// Async variant - runs blocking I/O on a dedicated thread pool.
    ///
    /// - Parameter path: Path to the baseline JSON file.
    /// - Returns: The deserialized measurement, or `nil` if the file does not exist.
    public static func load(
        at path: File.Path
    ) async throws(Kernel.Thread.Pool.Error) -> Test.Benchmark.Measurement? {
        let path = path
        let run:
            (
                Duration?, sending @escaping () -> Test.Benchmark.Measurement?
            ) async throws(Kernel.Thread.Pool.Error) -> sending Test.Benchmark.Measurement? = Kernel
                .Thread.Pool.shared.run
        return try await run(nil) {
            load(at: path)
        }
    }
}

extension Tests.Baseline.Storage {
    /// Saves a measurement as a baseline.
    ///
    /// Creates parent directories as needed. Writes atomically.
    ///
    /// - Parameters:
    ///   - measurement: The measurement to store.
    ///   - path: The destination path.
    /// - Throws: `Storage.Error` on failure.
    public static func save(
        _ measurement: Test.Benchmark.Measurement,
        to path: File.Path
    ) throws(Self.Error) {
        if let parent = path.parent {
            try ensureDirectory(at: parent)
        }

        let content = measurement.jsonString(pretty: true)
        do throws(File.System.Write.Atomic.Error) {
            try File(path).write.atomic(content)
        } catch {
            throw Self.Error.writeFailed(
                path: path,
                underlying: Swift.String(describing: error)
            )
        }
    }

    /// Saves a measurement as a baseline.
    ///
    /// Async variant - runs blocking I/O on a dedicated thread pool.
    ///
    /// - Parameters:
    ///   - measurement: The measurement to store.
    ///   - path: The destination path.
    public static func save(
        _ measurement: Test.Benchmark.Measurement,
        to path: File.Path
    ) async throws(Either<Kernel.Thread.Pool.Error, Tests.Baseline.Storage.Error>) {
        let measurement = measurement
        let path = path
        try await Kernel.Thread.Pool.shared.run { () throws(Self.Error) in
            try save(measurement, to: path)
        }
    }

    /// Ensures a directory exists, creating it recursively if needed.
    private static func ensureDirectory(
        at path: File.Path
    ) throws(Self.Error) {
        let dir = File.Directory(path)
        if dir.stat.exists { return }

        do throws(File.System.Create.Directory.Error) {
            try dir.create.recursive()
        } catch {
            throw Self.Error.directoryCreationFailed(
                path: path,
                underlying: Swift.String(describing: error)
            )
        }
    }
}
