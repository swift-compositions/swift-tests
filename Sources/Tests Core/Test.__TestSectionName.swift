extension Test {
    /// Platform-specific section names for test content.
    ///
    /// - Warning: This type is used by the `@Test` macro. Do not use directly.
    public enum __TestSectionName {
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
            public static let name = "__DATA_CONST,__swift5_tests"
        #elseif os(Linux) || os(FreeBSD) || os(OpenBSD) || os(Android)
            public static let name = "swift5_tests"
        #elseif os(Windows)
            public static let name = ".sw5test$B"
        #else
            public static let name = "swift5_tests"
        #endif
    }
}
