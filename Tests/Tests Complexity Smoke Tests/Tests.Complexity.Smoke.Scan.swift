import Synchronization

extension ComplexitySmokeTests {
    final class Scan: Sendable {
        private let values: [Int]
        private let sink = Mutex(0)

        init(count: Int) {
            values = Array(0..<count)
        }

        @inline(never)
        func callAsFunction(_ count: Int) {
            var sum = 0
            for value in values.prefix(count) {
                sum &+= value
            }
            sink.withLock { $0 = sum }
        }

        func report() {
            print("Linear scan sum: \(sink.withLock { $0 })")
        }
    }
}
