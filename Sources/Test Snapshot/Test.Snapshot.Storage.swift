// This source file is part of the swift-test-snapshot open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-test-snapshot project authors
// Licensed under Apache License v2.0

public import Byte_Primitives
internal import File_System
public import Test

extension Test.Snapshot {
    public enum Storage {}
}

extension Test.Snapshot.Storage {
    public static func read(_ reference: Test.Snapshot.Reference) throws(Error) -> [Byte]? {
        let file = File(reference.path)
        guard file.stat.exists else { return nil }
        do throws(Either<File.System.Read.Full.Error, Never>) {
            return try file.read.full { span in
                span.withUnsafeBufferPointer { unsafe Array($0) }
            }
        } catch {
            throw .read(reference: reference, underlying: Swift.String(describing: error))
        }
    }

    public static func write(
        _ bytes: [Byte],
        to reference: Test.Snapshot.Reference
    ) throws(Error) {
        if let parent = reference.path.parent {
            let directory = File.Directory(parent)
            if !directory.stat.exists {
                do throws(File.System.Create.Directory.Error) {
                    try directory.create.recursive()
                } catch {
                    throw .directory(reference: reference, underlying: Swift.String(describing: error))
                }
            }
        }
        do throws(File.System.Write.Atomic.Error) {
            try File(reference.path).write.atomic(contentsOf: bytes)
        } catch {
            throw .write(reference: reference, underlying: Swift.String(describing: error))
        }
    }
}
