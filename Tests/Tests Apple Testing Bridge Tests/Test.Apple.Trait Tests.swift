import Synchronization
import Testing
import Tests_Apple_Testing_Bridge

private typealias NeutralTest = Test_Primitives_Core.Test

private final class Trace: Sendable {
  let values = Mutex<[String]>([])
}

private struct TracingModifier: NeutralTest.Modifier {
  let inheritance: NeutralTest.Scope.Inheritance
  let trace: Trace

  func apply<R: ~Copyable, E: Swift.Error>(
    in context: NeutralTest.Context,
    isolation: isolated (any Actor)?,
    operation: @isolated(any) () async throws(E) -> sending R
  ) async throws(E) -> sending R {
    trace.values.withLock { $0.append("enter") }
    defer { trace.values.withLock { $0.append("leave") } }
    return try await operation()
  }
}

@Suite
struct `Test Apple Trait` {
  @Test
  func `generic wrapper invokes the scoped operation exactly once`() async throws {
    let trace = Trace()
    let trait = NeutralTest.Apple.Trait(
      TracingModifier(inheritance: .recursive, trace: trace)
    )
    let current = try #require(Testing.Test.current)
    try await trait.provideScope(for: current, testCase: nil) {
      #expect(NeutralTest.Context.current != nil)
      trace.values.withLock { $0.append("operation") }
    }

    #expect(trace.values.withLock { $0 }.filter { $0 == "operation" }.count == 1)
    #expect(trait.isRecursive)
    #expect(trace.values.withLock { $0 } == ["enter", "operation", "leave"])
  }
}
