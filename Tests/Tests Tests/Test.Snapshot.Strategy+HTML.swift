import HTML_Rendering_Core
import Testing
import Tests_Test_Support

extension Test::Test.Snapshot.Strategy where Value: HTML.Document.`Protocol`, Format == Swift.String {
    static var html: Self {
        .html()
    }

    static func html(configuration: HTML.Context.Configuration = .pretty) -> Self {
        Test::Test.Snapshot.Strategy(
            pathExtension: "html",
            diffing: Test::Test.Snapshot.Diffing.lines,
            snapshot: { value in
                HTML.Context.Configuration.$current.withValue(configuration) {
                    do {
                        return try Swift.String(value, configuration: configuration)
                    } catch {
                        Issue.record("HTML rendering failed: \(error)")
                        return "HTML rendering failed: \(error)"
                    }
                }
            }
        )
    }
}

extension Test::Test.Snapshot.Strategy where Value: HTML.View, Format == Swift.String {
    static var html: Self {
        .html()
    }

    static func html(configuration: HTML.Context.Configuration = .pretty) -> Self {
        Test::Test.Snapshot.Strategy(
            pathExtension: "html",
            diffing: Test::Test.Snapshot.Diffing.lines,
            snapshot: { value in
                HTML.Context.Configuration.$current.withValue(configuration) {
                    do {
                        return try Swift.String(value, configuration: configuration)
                    } catch {
                        Issue.record("HTML rendering failed: \(error)")
                        return "HTML rendering failed: \(error)"
                    }
                }
            }
        )
    }
}
