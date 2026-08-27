// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-tests",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "Tests Core", targets: ["Tests Core"]),
        .library(name: "Tests Snapshot", targets: ["Tests Snapshot"]),
        .library(name: "Tests Inline Snapshot", targets: ["Tests Inline Snapshot"]),
        .library(name: "Tests Performance", targets: ["Tests Performance"]),
        .library(name: "Tests Reporter", targets: ["Tests Reporter"]),
        .library(name: "Tests", targets: ["Tests"]),
        .library(name: "Tests Apple Testing Bridge", targets: ["Tests Apple Testing Bridge"]),
        .library(name: "Tests Test Support", targets: ["Tests Test Support"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-molecules/swift-ascii.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-test.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-binary.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-time.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-format.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-dependency.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-ownership.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-set.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-set-ordered.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-hash-table.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-column.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-ownership-shared.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-buffer-linear.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-byte.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-tree-keyed.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-compositions/swift-kernel.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-memory-mapping.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-console.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-file-system.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-io.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-json.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-loader.git", branch: "main"),
        .package(
            url: "https://github.com/swift-molecules/swift-sample.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-compositions/swift-clocks.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-environment.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-witnesses.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-html-render.git", branch: "main"),
        .package(url: "https://github.com/swift-iec/swift-iec-80000-13.git", branch: "main"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "602.0.0"..<"603.0.0"),
    ],
    targets: [

        // MARK: - Core

        .target(
            name: "Tests Core",
            dependencies: [
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Test", package: "swift-test"),
                .product(name: "Ownership", package: "swift-ownership"),
                .product(name: "Dependency", package: "swift-dependency"),
                .product(name: "Loader", package: "swift-loader"),
                .product(name: "Witnesses", package: "swift-witnesses"),
                .product(name: "Set", package: "swift-set"),
                .product(name: "Set Ordered", package: "swift-set-ordered"),
                .product(name: "Tree Keyed", package: "swift-tree-keyed"),
                .product(name: "Hash Indexed Primitive", package: "swift-hash-table"),
                .product(name: "Column", package: "swift-column"),
                .product(
                    name: "Ownership Shared Primitive",
                    package: "swift-ownership-shared"
                ),
                .product(
                    name: "Buffer Linear Primitive",
                    package: "swift-buffer-linear"
                ),
            ]
        ),

        // MARK: - Snapshot

        .target(
            name: "Tests Snapshot",
            dependencies: [
                "Tests Core",
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "Dependency", package: "swift-dependency"),
                .product(name: "Kernel", package: "swift-kernel"),
                .product(
                    name: "Byte Standard Library Integration",
                    package: "swift-byte"
                ),
            ]
        ),

        // MARK: - Inline Snapshot

        .target(
            name: "Tests Inline Snapshot",
            dependencies: [
                "Tests Snapshot",
                "Tests Apple Testing Bridge",
                .product(name: "HTML Snapshot Test Support", package: "swift-html-render"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ]
        ),

        // MARK: - Performance

        .target(
            name: "Tests Performance",
            dependencies: [
                "Tests Core",
                .product(name: "Sample", package: "swift-sample"),
                .product(name: "Time", package: "swift-time"),
                .product(name: "Console", package: "swift-console"),
                .product(name: "Kernel", package: "swift-kernel"),
                .product(name: "Memory Mapping", package: "swift-memory-mapping"),
                .product(name: "Binary", package: "swift-binary"),
                .product(name: "Format", package: "swift-format"),
                .product(name: "Dependency", package: "swift-dependency"),
                .product(name: "Clocks", package: "swift-clocks"),
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "Environment", package: "swift-environment"),
                .product(name: "IO", package: "swift-io"),
                .product(name: "IEC 80000-13 Formatting", package: "swift-iec-80000-13"),
            ]
        ),

        // MARK: - Reporter

        .target(
            name: "Tests Reporter",
            dependencies: [
                "Tests Core",
                .product(name: "Console", package: "swift-console"),
                .product(name: "Kernel", package: "swift-kernel"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "Time", package: "swift-time"),
            ]
        ),

        // MARK: - Umbrella

        .target(
            name: "Tests",
            dependencies: [
                "Tests Core",
                "Tests Reporter",
                "Tests Snapshot",
                "Tests Performance",
            ]
        ),

        // MARK: - Apple Testing Bridge

        .target(
            name: "Tests Apple Testing Bridge",
            dependencies: [
                "Tests Snapshot",
                .product(name: "Dependency", package: "swift-dependency"),
            ]
        ),

        // MARK: - Test Support

        .target(
            name: "Tests Test Support",
            dependencies: [
                "Tests",
                .product(
                    name: "Test Test Support",
                    package: "swift-test"
                ),
                .product(
                    name: "Kernel Test Support",
                    package: "swift-kernel"
                ),
                .product(
                    name: "File System Test Support",
                    package: "swift-file-system"
                ),
            ],
            path: "Tests/Support"
        ),

        // MARK: - Tests

        .testTarget(
            name: "Tests Tests",
            dependencies: [
                "Tests",
                "Tests Inline Snapshot",
                "Tests Test Support",
            ],
            // Explicit path: the nested test manifest at Tests/Package.swift makes
            // SwiftPM skip automatic target discovery under Tests/.
            path: "Tests/Tests Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
