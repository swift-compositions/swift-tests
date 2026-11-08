public import Cardinal
import Kernel
import Tagged
import Time

extension Test {
    /// Runtime and compile-time environment fingerprint for performance diagnostics.
    ///
    /// Captures hardware characteristics, compiler settings, and feature flags
    /// that affect performance measurement. Used to explain regressions caused
    /// by environment differences (e.g., debug vs release, feature flags enabled).
    public struct Environment: Sendable, Hashable {
        /// CPU architecture (e.g., "arm64", "x86_64").
        public var architecture: Swift.String

        /// Number of physical CPU cores.
        public var physicalCPUCount: Int

        /// Number of logical CPU cores (includes hyperthreading).
        public var logicalCPUCount: Int

        /// Total physical memory in bytes.
        public var memoryBytes: Cardinal

        /// OS version string (e.g., "Darwin 24.3.0").
        // swift-linter:disable:next raw concept
        // REASON: the host's description for a benchmark report, such as Darwin 24.3.0; looked at Version.Semantic and Version.Tools, which refuse the system's name in front.
        public var osVersion: Swift.String

        /// Swift compiler version (compile-time detected range).
        // swift-linter:disable:next raw concept
        // REASON: the compile-time detected range of the Swift compiler as report text, not one version; looked at Version.Semantic and Version.Tools, which hold a single version.
        public var swiftVersion: Swift.String

        /// Build optimization level.
        public var optimization: Optimization

        /// Enabled Swift feature flags.
        ///
        /// Note: detects flags for the *swift-tests* compilation unit, not necessarily
        /// the test target's compilation unit. Still valuable for diagnosing whether
        /// the test framework itself was compiled with those flags.
        public var features: Features

        public init(
            architecture: Swift.String,
            physicalCPUCount: Int,
            logicalCPUCount: Int,
            memoryBytes: Cardinal,
            // swift-linter:disable:next raw concept
            // REASON: the host's description for a benchmark report, such as Darwin 24.3.0; looked at Version.Semantic and Version.Tools, which refuse the system's name in front.
            osVersion: Swift.String,
            // swift-linter:disable:next raw concept
            // REASON: the compile-time detected range of the Swift compiler as report text, not one version; looked at Version.Semantic and Version.Tools, which hold a single version.
            swiftVersion: Swift.String,
            optimization: Optimization,
            features: Features
        ) {
            self.architecture = architecture
            self.physicalCPUCount = physicalCPUCount
            self.logicalCPUCount = logicalCPUCount
            self.memoryBytes = memoryBytes
            self.osVersion = osVersion
            self.swiftVersion = swiftVersion
            self.optimization = optimization
            self.features = features
        }
    }
}

extension Test.Environment {
    /// Captures the current runtime and compile-time environment.
    public static func capture() -> Self {
        let osVersion = Kernel.Name.current.map { "\($0.system) \($0.release)" } ?? "unknown"
        let physical = Int(CPU.Core.count)
        let logical = Int(CPU.Logical.count)
        let memory = Memory.Physical.capacity.underlying
        return Self(
            architecture: _architecture,
            physicalCPUCount: physical,
            logicalCPUCount: logical,
            memoryBytes: memory,
            osVersion: osVersion,
            swiftVersion: _swiftVersion,
            optimization: .current,
            features: .current
        )
    }

    /// Human-readable fingerprint for file keying and display.
    ///
    /// Example: `"arm64-10c-debug-nnbd-sms"` or `"x86_64-8c-release"`
    public var fingerprint: Swift.String {
        var parts = [architecture, "\(physicalCPUCount)c"]
        parts.append(optimization.rawValue)
        if features.nonisolatedNonsendingByDefault { parts.append("nnbd") }
        if features.strictMemorySafety { parts.append("sms") }
        return parts.joined(separator: "-")
    }
}

extension Test.Environment {
    private static var _architecture: Swift.String {
        #if arch(arm64)
            "arm64"
        #elseif arch(x86_64)
            "x86_64"
        #elseif arch(i386)
            "i386"
        #else
            "unknown"
        #endif
    }

    private static var _swiftVersion: Swift.String {
        #if swift(>=6.2)
            "6.2"
        #elseif swift(>=6.1)
            "6.1"
        #elseif swift(>=6.0)
            "6.0"
        #else
            "< 6.0"
        #endif
    }
}
