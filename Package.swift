// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-test-snapshot",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "Test Snapshot", targets: ["Test Snapshot"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-primitives/swift-test.git",
            branch: "testing-stack/neutral-test-boundary"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-snapshot.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-source-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-byte-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-foundations/swift-file-system.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "Test Snapshot",
            dependencies: [
                .product(name: "Test", package: "swift-test"),
                .product(name: "Snapshot", package: "swift-snapshot"),
                .product(name: "Source Primitives", package: "swift-source-primitives"),
                .product(name: "Byte Primitives", package: "swift-byte-primitives"),
                .product(name: "File System", package: "swift-file-system"),
            ]
        ),
        .testTarget(
            name: "Test Snapshot Tests",
            dependencies: [
                .target(name: "Test Snapshot"),
                .product(name: "Test", package: "swift-test"),
                .product(name: "Snapshot", package: "swift-snapshot"),
                .product(name: "Source Primitives", package: "swift-source-primitives"),
                .product(name: "File System", package: "swift-file-system"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]
    let memberVisibility: [SwiftSetting] = target.name == "Test Snapshot"
        ? [.enableUpcomingFeature("MemberImportVisibility")]
        : []
    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + memberVisibility
}
