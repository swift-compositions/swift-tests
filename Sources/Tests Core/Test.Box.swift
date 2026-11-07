public import Ownership

extension Test {
    /// Typealias to Ownership.Shared for API compatibility.
    ///
    /// Used by @Test macro expansion to box registrations for transfer
    /// via C-compatible function signatures.
    ///
    /// - SeeAlso: `Ownership.Box` from swift-ownership
    public typealias Box<T: Sendable> = Ownership.Box<T>
}
