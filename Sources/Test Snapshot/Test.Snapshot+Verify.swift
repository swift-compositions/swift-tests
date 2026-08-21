// This source file is part of the swift-test-snapshot open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-test-snapshot project authors
// Licensed under Apache License v2.0

internal import Byte_Primitives
public import Snapshot
public import Test

extension Test.Snapshot {
    public static func verify<Input: Sendable, Output: Sendable>(
        _ input: Input,
        as strategy: Snapshot.Strategy<Input, Output>,
        reference: Reference,
        recording: Recording = Configuration.current.recording
    ) async throws(Storage.Error) -> Result {
        let output = await strategy.capture(input)
        let encoded = strategy.representation.encode(output)
        let bytes = encoded.map(Byte.init)
        let stored = try Storage.read(reference)

        guard let stored else {
            if recording != .never {
                try Storage.write(bytes, to: reference)
                return .recorded(reference)
            }
            return .failed(.init(reference: reference, summary: "Snapshot reference is missing"))
        }

        guard let expected = strategy.representation.decode(stored.map(\.underlying)) else {
            return .failed(.init(reference: reference, summary: "Snapshot reference cannot be decoded"))
        }
        let difference = strategy.comparison.difference(expected, output)

        if recording == .all {
            try Storage.write(bytes, to: reference)
            return .recorded(reference)
        }
        guard let difference else { return .matched }
        if recording == .failed {
            try Storage.write(bytes, to: reference)
        }
        return .failed(
            .init(reference: reference, summary: difference.summary, difference: difference)
        )
    }
}
