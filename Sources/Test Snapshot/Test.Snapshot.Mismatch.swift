// This source file is part of the swift-test-snapshot open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-test-snapshot project authors
// Licensed under Apache License v2.0

public import Snapshot
public import Test

extension Test.Snapshot {
    public struct Mismatch: Sendable, Hashable {
        public let reference: Reference
        public let summary: Swift.String
        public let difference: Snapshot.Difference?

        public init(
            reference: Reference,
            summary: Swift.String,
            difference: Snapshot.Difference? = nil
        ) {
            self.reference = reference
            self.summary = summary
            self.difference = difference
        }
    }
}
