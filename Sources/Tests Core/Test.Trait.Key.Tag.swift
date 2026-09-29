//
//  Test.Trait.Key.Tag.swift
//  swift-tests
//
//  Witness key for tag traits.
//

public import Buffer_Linear_Primitive
public import Memory
public import Memory_Allocator
public import Storage
public import Buffer

public import Hash_Indexed_Primitive
public import Ownership_Shared_Primitive
public import Set_Ordered
public import Set

extension Test.Trait {
    /// Witness key for tag collection.
    public struct Tag: Sendable {}
}

extension Test.Trait.Tag: Witness.Key {
    public typealias Value = __SetOrdered<
        Ownership.Shared<Swift.String, Hash.Indexed<Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Swift.String>>.Linear>>
    >

    @inlinable
    public static var liveValue: Value { .init() }
}
