//
//  Test.Apple.Trait.swift
//  swift-tests
//
//  Generic neutral-modifier adaptation to Apple Testing traits.
//

public import Test_Primitives_Core
public import Testing

extension Test_Primitives_Core.Test.Apple {
  /// Adapts one neutral modifier to Apple suite and test scoping.
  public struct Trait<Modifier: Test_Primitives_Core.Test.Modifier>: Sendable {
    public let modifier: Modifier
    public let context: Test_Primitives_Core.Test.Context

    public init(
      _ modifier: Modifier,
      context: Test_Primitives_Core.Test.Context = .init(
        recorder: Test_Primitives_Core.Test.Apple.recorder
      )
    ) {
      self.modifier = modifier
      self.context = context
    }
  }
}

extension Test_Primitives_Core.Test.Apple.Trait: Testing.SuiteTrait, Testing.TestTrait {
  public var isRecursive: Bool {
    modifier.inheritance == .recursive
  }
}

extension Test_Primitives_Core.Test.Apple.Trait: Testing.TestScoping {
  @concurrent
  public func provideScope(
    for test: Testing.Test,
    testCase: Testing.Test.Case?,
    performing function: @Sendable @concurrent () async throws -> Void
  ) async throws {
    try await context.withCurrent {
      try await modifier.apply(
        in: context,
        isolation: #isolation,
        operation: {
          try await function()
        }
      )
    }
  }
}
