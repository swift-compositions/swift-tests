// This source file is part of the swift-test-snapshot open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-test-snapshot project authors
// Licensed under Apache License v2.0

public import Test

extension Test.Snapshot.Reference {
    public struct Index: Sendable, Hashable {
        public let value: UInt

        public init(_ value: UInt) {
            self.value = value
        }
    }
}
