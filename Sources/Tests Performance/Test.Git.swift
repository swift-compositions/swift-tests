//
//  Test.Git.swift
//  swift-tests
//
//  Best-effort git metadata capture.
//

import File_System

extension Test {
    /// Git repository state at test run time.
    ///
    /// Captured by reading `.git/HEAD` and resolving refs directly —
    /// no subprocess spawning required.
    public struct Git: Sendable {
        /// The current commit SHA, or nil if unavailable.
        public let sha: Swift.String?

        /// The current branch name, or nil if detached or unavailable.
        public let branch: Swift.String?

        /// Whether the working tree has uncommitted changes.
        ///
        /// Always `nil` — determining dirty status requires `git status`
        /// which needs subprocess spawning. Deferred for now.
        public let dirty: Bool?
    }
}

extension Test.Git {
    /// Captures git metadata from the current working directory.
    ///
    /// Reads `.git/HEAD` to determine branch and SHA.
    /// Returns nil fields if not in a git repository.
    public static func capture() -> Self {
        guard let head = _read(".git/HEAD") else {
            return Self(sha: nil, branch: nil, dirty: nil)
        }

        let refPrefix = "ref: "
        if head.hasPrefix(refPrefix) {
            let ref = Swift.String(head.dropFirst(refPrefix.count))
            let sha = _read(".git/\(ref)")
            let branchPrefix = "refs/heads/"
            let branch =
                ref.hasPrefix(branchPrefix)
                ? Swift.String(ref.dropFirst(branchPrefix.count))
                : nil
            return Self(sha: sha, branch: branch, dirty: nil)
        }

        // Detached HEAD — head content is the SHA
        return Self(sha: head, branch: nil, dirty: nil)
    }
}

// MARK: - File Reading

/// Reads the trimmed contents of a file, or nil if unavailable.
private func _read(_ path: Swift.String) -> Swift.String? {
    let file = File(File.Path(stringLiteral: path))
    guard file.stat.exists else { return nil }
    var result: Swift.String
    do throws(Either<File.System.Read.Full.Error, Never>) {
        result = try file.read.full { span in
            unsafe span.withUnsafeBufferPointer { buffer in
                unsafe Swift.String(decoding: buffer, as: UTF8.self)
            }
        }
    } catch {
        return nil
    }

    // Trim trailing whitespace/newlines
    while let last = result.unicodeScalars.last,
        last == "\n" || last == "\r" || last == " " || last == "\t"
    {
        result.unicodeScalars.removeLast()
    }

    return result.isEmpty ? nil : result
}
