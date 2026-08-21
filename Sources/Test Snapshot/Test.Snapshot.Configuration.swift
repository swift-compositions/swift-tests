// This source file is part of the swift-test-snapshot open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-test-snapshot project authors
// Licensed under Apache License v2.0

public import File_System
public import Test

extension Test.Snapshot {
    public struct Configuration: Sendable {
        public let recording: Recording
        public let directory: File.Path?
        public let subdirectory: File.Path.Component?

        public init(
            recording: Recording = .missing,
            directory: File.Path? = nil,
            subdirectory: File.Path.Component? = nil
        ) {
            self.recording = recording
            self.directory = directory
            self.subdirectory = subdirectory
        }
    }
}

extension Test.Snapshot.Configuration {
    @TaskLocal public static var current = Self()
}
