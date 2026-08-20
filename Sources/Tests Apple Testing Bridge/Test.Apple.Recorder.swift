//
//  Test.Apple.Recorder.swift
//  swift-tests
//
//  Explicit conversion from neutral issues to Apple Testing issues.
//

public import Test_Primitives_Core
internal import Testing

extension Test_Primitives_Core.Test {
  /// Namespace for Apple Testing adaptation.
  public enum Apple {}
}

extension Test_Primitives_Core.Test.Apple {
  /// A neutral recorder that forwards issues to the current Apple test.
  public static var recorder: Test_Primitives_Core.Test.Recorder {
    .init { issue in
      let location = issue.sourceLocation.map {
        Testing.SourceLocation(
          fileID: $0.fileID,
          filePath: $0.filePath ?? $0.fileID,
          line: Swift.Int($0.line.underlying),
          column: Swift.Int($0.column.underlying.rawValue)
        )
      }

      if let location {
        Testing.Issue.record(
          Testing.Comment(rawValue: issue.description),
          sourceLocation: location
        )
      } else {
        Testing.Issue.record(Testing.Comment(rawValue: issue.description))
      }
    }
  }
}
