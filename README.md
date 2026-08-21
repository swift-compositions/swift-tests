# Test Snapshot

[![CI](https://github.com/swift-foundations/swift-test-snapshot/actions/workflows/ci.yml/badge.svg)](https://github.com/swift-foundations/swift-test-snapshot/actions/workflows/ci.yml)

The Test × Snapshot relation: assertions, mismatch-to-issue mapping, recording policy, reference naming, atomic file storage, and runner-neutral scoped configuration.

```swift
import Test_Snapshot

let result = try await Test.Snapshot.verify(
    "hello",
    as: .lines,
    reference: reference
)
```

The target itself imports no Apple Testing, SwiftSyntax, Benchmark, Clock, Memory, JSON,
Console, HTML, or reporter module. Its current File System dependency still carries a
broader package-resolution closure, so package-level closure isolation is not yet satisfied.

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
