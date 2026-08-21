// This source file is part of the swift-test-snapshot open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-test-snapshot project authors
// Licensed under Apache License v2.0

public import Test

extension Test.Snapshot {
    /// Controls whether missing, mismatching, or all references are recorded.
    public enum Recording: Swift.String, Sendable, Hashable, Codable, CaseIterable {
        case never
        case missing
        case failed
        case all
    }
}
