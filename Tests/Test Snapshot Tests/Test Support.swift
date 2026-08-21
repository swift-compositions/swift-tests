// This source file is part of the swift-test-snapshot open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-test-snapshot project authors
// Licensed under Apache License v2.0

import File_System
import Foundation
import Snapshot
import Test
import Test_Snapshot

typealias NeutralTest = Test
typealias GenericSnapshot = Snapshot

enum Fixture {}

extension Fixture {
    struct Reference {
        let directory: URL
        let reference: NeutralTest.Snapshot.Reference

        init(_ name: consuming Swift.String = "reference.txt") {
            self.directory = FileManager.default.temporaryDirectory
                .appending(path: "swift-test-snapshot-\(UUID().uuidString)", directoryHint: .isDirectory)
            self.reference = .init(
                path: File.Path(stringLiteral: directory.appending(path: name).path())
            )
        }
    }
}

extension Fixture.Reference {
    func clean() {
        // swift-linter:disable:next try optional
        // REASON: FileManager.removeItem(at:) exposes only untyped throws and cleanup is best-effort.
        try? FileManager.default.removeItem(at: directory)
    }
}
