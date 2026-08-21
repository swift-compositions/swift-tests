// This source file is part of the swift-test-snapshot open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-test-snapshot project authors
// Licensed under Apache License v2.0

import Synchronization
import Source_Primitives
import Testing

@Suite
struct `Test Snapshot Tests` {
    @Suite
    struct Unit {
        @Test
        func `missing-reference recording truth table`() async throws {
            for (mode, records) in [
                (NeutralTest.Snapshot.Recording.never, false),
                (.missing, true),
                (.failed, true),
                (.all, true),
            ] {
                let fixture = Fixture.Reference()
                defer { fixture.clean() }
                let result = try await NeutralTest.Snapshot.verify(
                    "value",
                    as: GenericSnapshot.Strategy<String, String>.lines,
                    reference: fixture.reference,
                    recording: mode
                )

                if records {
                    #expect(result == .recorded(fixture.reference))
                } else if case .failed(let mismatch) = result {
                    #expect(mismatch.summary.contains("missing"))
                } else {
                    Issue.record("Expected missing-reference failure")
                }
            }
        }

        @Test
        func `match and mismatch recording truth table`() async throws {
            let fixture = Fixture.Reference()
            defer { fixture.clean() }
            _ = try await NeutralTest.Snapshot.verify(
                "old",
                as: GenericSnapshot.Strategy<String, String>.lines,
                reference: fixture.reference,
                recording: .missing
            )

            #expect(
                try await NeutralTest.Snapshot.verify(
                    "old",
                    as: GenericSnapshot.Strategy<String, String>.lines,
                    reference: fixture.reference,
                    recording: .never
                ) == .matched
            )

            let mismatch = try await NeutralTest.Snapshot.verify(
                "new",
                as: GenericSnapshot.Strategy<String, String>.lines,
                reference: fixture.reference,
                recording: .missing
            )
            guard case .failed(let difference) = mismatch else {
                Issue.record("Expected mismatch")
                return
            }
            #expect(difference.difference?.lines.isEmpty == false)

            let failed = try await NeutralTest.Snapshot.verify(
                "new",
                as: GenericSnapshot.Strategy<String, String>.lines,
                reference: fixture.reference,
                recording: .failed
            )
            guard case .failed = failed else {
                Issue.record("Failed mode must record and still fail")
                return
            }
            #expect(
                try await NeutralTest.Snapshot.verify(
                    "new",
                    as: GenericSnapshot.Strategy<String, String>.lines,
                    reference: fixture.reference,
                    recording: .never
                ) == .matched
            )

            #expect(
                try await NeutralTest.Snapshot.verify(
                    "newest",
                    as: GenericSnapshot.Strategy<String, String>.lines,
                    reference: fixture.reference,
                    recording: .all
                ) == .recorded(fixture.reference)
            )
        }
    }

    @Suite
    struct `Edge Case` {
        @Test
        func `reference names derive from source function index and suffix`() {
            let source = Source.Location(
                fileID: "FeatureTests/Feature Tests.swift",
                filePath: "Fixtures/Feature Tests.swift",
                line: 12,
                column: 3
            )
            let reference = NeutralTest.Snapshot.Reference(
                source: source,
                function: "renders(value:)",
                index: .init(2),
                suffix: "txt"
            )

            #expect(String(describing: reference.path).hasSuffix(".snapshots/renders.2.txt"))
        }
    }

    @Suite
    struct Integration {
        @Test
        func `modifier preserves exactly-once generic operation semantics`() async {
            let invocations = Mutex(0)
            let modifier = NeutralTest.Snapshot.Modifier(
                configuration: .init(recording: .all)
            )
            let context = NeutralTest.Context(
                recorder: .init(issue: { _ in }, attachment: { _ in })
            )

            let value = await modifier.apply(
                in: context,
                isolation: #isolation
            ) {
                invocations.withLock { $0 += 1 }
                return 42
            }

            #expect(value == 42)
            #expect(invocations.withLock { $0 } == 1)
        }

        @Test
        func `modifier scopes snapshot configuration for a test body`() async {
            let modifier = NeutralTest.Snapshot.Modifier(
                configuration: .init(recording: .all)
            )
            let context = NeutralTest.Context(
                recorder: .init(issue: { _ in }, attachment: { _ in })
            )

            await modifier.scope(in: context, isolation: #isolation) {
                #expect(NeutralTest.Snapshot.Configuration.current.recording == .all)
                #expect(NeutralTest.Context.current != nil)
            }

            #expect(NeutralTest.Snapshot.Configuration.current.recording == .missing)
            #expect(NeutralTest.Context.current == nil)
        }

        @Test
        func `assert maps mismatch to an explicit issue and attachment`() async throws {
            let fixture = Fixture.Reference()
            defer { fixture.clean() }
            _ = try await NeutralTest.Snapshot.verify(
                "old",
                as: GenericSnapshot.Strategy<String, String>.lines,
                reference: fixture.reference,
                recording: .missing
            )
            let issues = Mutex<[NeutralTest.Issue]>([])
            let attachments = Mutex<[NeutralTest.Attachment]>([])
            let recorder = NeutralTest.Recorder(
                issue: { issue in issues.withLock { $0.append(issue) } },
                attachment: { attachment in attachments.withLock { $0.append(attachment) } }
            )

            let result = try await NeutralTest.Snapshot.assert(
                "new",
                as: GenericSnapshot.Strategy<String, String>.lines,
                reference: fixture.reference,
                recording: .never,
                recorder: recorder
            )

            guard case .failed = result else {
                Issue.record("Expected failure")
                return
            }
            #expect(issues.withLock { $0.count } == 1)
            #expect(attachments.withLock { $0.count } == 1)
        }
    }
}
