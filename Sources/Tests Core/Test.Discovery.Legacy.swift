extension Test {
    /// Protocol for legacy test content record containers.
    ///
    /// On Swift < 6.3, the `@Test` macro emits an enum conforming to this
    /// protocol instead of placing records in a binary section. Discovery finds
    /// these types by scanning the `__swift5_types` section for types named
    /// `__🟡$...`.
    ///
    /// - Warning: This protocol is an implementation detail of the `@Test` macro.
    @_alwaysEmitConformanceMetadata
    public protocol __TestContentRecordContainer {
        // swift-format-ignore: AlwaysUseLowerCamelCase
        nonisolated static var __testContentRecord: Test.__TestContentRecord { get }
    }
}
