// This source file is part of the swift-test-snapshot open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-test-snapshot project authors
// Licensed under Apache License v2.0

public import Snapshot
public import Test

extension Test.Snapshot {
    public static func assert<Input: Sendable, Output: Sendable>(
        _ input: Input,
        as strategy: Snapshot.Strategy<Input, Output>,
        reference: Reference,
        recording: Recording = Configuration.current.recording,
        recorder: Test.Recorder
    ) async throws(Storage.Error) -> Result {
        let result = try await verify(
            input,
            as: strategy,
            reference: reference,
            recording: recording
        )
        if case .failed(let mismatch) = result {
            recorder(
                .init(
                    kind: .assertion,
                    message: .init(mismatch.summary),
                    source: Test.Context.current?.source
                )
            )
            if let difference = mismatch.difference {
                recorder.record(
                    .init(
                        name: "\(reference.path).diff.txt",
                        text: difference.description
                    )
                )
            }
        }
        return result
    }
}
