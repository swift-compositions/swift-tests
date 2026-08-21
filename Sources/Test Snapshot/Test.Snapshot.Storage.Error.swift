// This source file is part of the swift-test-snapshot open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-test-snapshot project authors
// Licensed under Apache License v2.0

public import Test

extension Test.Snapshot.Storage {
    public enum Error: Swift.Error, Sendable {
        case read(reference: Test.Snapshot.Reference, underlying: Swift.String)
        case write(reference: Test.Snapshot.Reference, underlying: Swift.String)
        case directory(reference: Test.Snapshot.Reference, underlying: Swift.String)
    }
}
