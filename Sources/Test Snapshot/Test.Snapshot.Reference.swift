// This source file is part of the swift-test-snapshot open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-test-snapshot project authors
// Licensed under Apache License v2.0

public import File_System
public import Source_Primitives
public import Test

extension Test.Snapshot {
    public struct Reference: Sendable, Hashable {
        public let path: File.Path

        public init(path: File.Path) {
            self.path = path
        }
    }
}

extension Test.Snapshot.Reference {
    public init(
        source: Source.Location,
        function: consuming Swift.String,
        name: consuming Swift.String? = nil,
        index: Test.Snapshot.Reference.Index = .init(1),
        suffix: consuming Swift.String? = nil,
        configuration: Test.Snapshot.Configuration = .current
    ) {
        let sourcePath = File.Path(stringLiteral: source.filePath ?? source.fileID)
        let parent = sourcePath.parent ?? sourcePath
        var directory = configuration.directory ?? (parent / ".snapshots")
        if let subdirectory = configuration.subdirectory {
            directory = directory / subdirectory
        }
        let fallback = copy function
        let function = function.split(separator: "(", maxSplits: 1).first.map(Swift.String.init) ?? fallback
        let stem = name ?? "\(function).\(index.value)"
        let suffix = suffix ?? "snap"
        self.init(path: directory / "\(stem).\(suffix)")
    }
}
