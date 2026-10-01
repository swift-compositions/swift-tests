//
//  Test.Snapshot.Diffing+Structural.swift
//  swift-tests
//
//  Structural JSON diffing — tree-aware comparison.
//

import Byte
import JSON
public import Test
internal import Tree_Keyed

// MARK: - Structural JSON Diffing

extension Test.Snapshot.Diffing where Format == Swift.String {
    /// Structural JSON diff — parses to tree, compares by key, produces semantic output.
    ///
    /// Unlike ``lines`` which compares text line-by-line, structural diffing
    /// understands JSON semantics. It identifies exactly which keys changed,
    /// were added, or were removed — independent of formatting or key ordering.
    ///
    /// ## Example Output
    ///
    /// ```
    /// 3 structural changes:
    /// + email: "alice@example.com"
    /// ~ name: "Alice" → "Bob"
    /// - phone: "555-1234"
    /// ```
    public static var structuralJSON: Self {
        structuralJSON()
    }

    /// Structural JSON diff with formatting options.
    ///
    /// - Parameters:
    ///   - sortKeys: Whether to sort keys in serialized output. Default: `true`.
    ///   - pretty: Whether to pretty-print serialized output. Default: `true`.
    /// - Returns: A diffing strategy that performs structural JSON comparison.
    public static func structuralJSON(
        sortKeys: Bool = true,
        pretty: Bool = true
    ) -> Self {
        Self(
            toBytes: { $0.utf8.map(Byte.init(bitPattern:)) },
            fromBytes: { Swift.String(decoding: $0.map(\.bitPattern), as: UTF8.self) },
            diff: { old, new in
                let oldValue: RFC_8259.Value
                let newValue: RFC_8259.Value
                do throws(RFC_8259.Error) {
                    oldValue = try JSON.Decode.parse(old)
                    newValue = try JSON.Decode.parse(new)
                } catch {
                    // Not valid JSON — fall back to line diff
                    return Self.lines.diff(old, new)
                }

                let oldTree: __Tree<TreeStorage.Keyed<RFC_8259.Value, Swift.String>>
                let newTree: __Tree<TreeStorage.Keyed<RFC_8259.Value, Swift.String>>
                do throws(__Tree<TreeStorage.Keyed<RFC_8259.Value, Swift.String>>.Error) {
                    oldTree = try _jsonToKeyedTree(oldValue)
                    newTree = try _jsonToKeyedTree(newValue)
                } catch {
                    // Duplicate object member names make the structural mapping
                    // ill-defined — fall back to line diff, like invalid JSON.
                    return Self.lines.diff(old, new)
                }
                let treeDiff = __Tree<TreeStorage.Keyed<RFC_8259.Value, Swift.String>>.diff(
                    from: oldTree,
                    to: newTree
                )

                guard !treeDiff.isEmpty else { return nil }

                // Build structural operations (format-agnostic)
                let structuralOps: [Test.Snapshot.Diff.Result.Operation] =
                    treeDiff.operations.compactMap { op in
                        switch op {
                        case .added(let path, let value):
                            guard !_jsonIsContainer(value) else { return nil }
                            return .added(
                                path: _jsonFormatPath(path),
                                value: _jsonDisplayValue(value)
                            )

                        case .removed(let path, let value):
                            guard !_jsonIsContainer(value) else { return nil }
                            return .removed(
                                path: _jsonFormatPath(path),
                                value: _jsonDisplayValue(value)
                            )

                        case .modified(let path, let old, let new):
                            return .modified(
                                path: _jsonFormatPath(path),
                                old: _jsonDisplayValue(old),
                                new: _jsonDisplayValue(new)
                            )
                        }
                    }

                // Build summary
                let lines: [Swift.String] = structuralOps.map { op in
                    switch op {
                    case .added(let path, let value):
                        "+ \(path): \(value)"

                    case .removed(let path, let value):
                        "- \(path): \(value)"

                    case .modified(let path, let old, let new):
                        "~ \(path): \(old) → \(new)"
                    }
                }

                let count = structuralOps.count
                let noun = count == 1 ? "change" : "changes"
                let summary = "\(count) structural \(noun):\n" + lines.joined(separator: "\n")

                return Test.Snapshot.Diff.Result(
                    summary: summary,
                    structuralOperations: structuralOps
                )
            }
        )
    }
}
