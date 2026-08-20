//
//  Test.Expectation+Factory.swift
//  swift-tests
//
//  Convenience factories for creating and recording expectations.
//

import Synchronization
public import Test_Primitives

// MARK: - ID Counters

private let _expressionCounter = Atomic<UInt64>(0)
private let _expectationCounter = Atomic<UInt64>(0)

func _nextExpressionID() -> Test.Expression.ID {
    Test.Expression.ID(
        _unchecked: _expressionCounter.wrappingAdd(1, ordering: .relaxed).newValue
    )
}

func _nextExpectationID() -> Test.Expectation.ID {
    Test.Expectation.ID(
        _unchecked: _expectationCounter.wrappingAdd(1, ordering: .relaxed).newValue
    )
}

extension Test.Expectation {
    /// Records a neutral issue when no incumbent collector is active.
    static func _recordIssue(
        _ message: Swift.String,
        at location: Source.Location
    ) {
        guard Collector.current == nil else { return }
        Test.Context.current?.recorder(
            .init(
                kind: .unconditional(Test.Text(message)),
                sourceLocation: location
            )
        )
    }
}

// MARK: - Factories

extension Test.Expectation {
    /// Creates a passing expectation.
    ///
    /// - Parameters:
    ///   - sourceCode: Source code representation of the assertion.
    ///   - location: Source location of the assertion.
    /// - Returns: A passing expectation with auto-generated IDs.
    public static func passing(
        sourceCode: Swift.String,
        at location: Source.Location
    ) -> Self {
        let expression = Test.Expression(
            id: _nextExpressionID(),
            sourceCode: sourceCode,
            sourceLocation: location
        )
        return Self(
            id: _nextExpectationID(),
            expression: expression,
            isPassing: true
        )
    }

    /// Creates a failing expectation.
    ///
    /// - Parameters:
    ///   - message: Description of the failure.
    ///   - sourceCode: Source code representation of the assertion.
    ///   - location: Source location of the assertion.
    /// - Returns: A failing expectation with auto-generated IDs.
    public static func failing(
        _ message: Swift.String,
        sourceCode: Swift.String,
        at location: Source.Location
    ) -> Self {
        let expression = Test.Expression(
            id: _nextExpressionID(),
            sourceCode: sourceCode,
            sourceLocation: location
        )
        return Self(
            id: _nextExpectationID(),
            expression: expression,
            isPassing: false,
            failure: Failure(message: Test.Text(message))
        )
    }

    // MARK: - Create + Record

    /// Creates a passing expectation and records it with the current collector.
    ///
    /// - Parameters:
    ///   - sourceCode: Source code representation of the assertion.
    ///   - location: Source location of the assertion.
    /// - Returns: The recorded passing expectation.
    @discardableResult
    public static func record(
        passing sourceCode: Swift.String,
        at location: Source.Location
    ) -> Self {
        let result = passing(sourceCode: sourceCode, at: location)
        Collector.current?.record(result)
        return result
    }

    /// Creates a failing expectation and records it with the current collector.
    ///
    /// When no collector is installed, the failure is sent to the explicit
    /// recorder in ``Test/Context/current``.
    ///
    /// - Parameters:
    ///   - message: Description of the failure.
    ///   - sourceCode: Source code representation of the assertion.
    ///   - location: Source location of the assertion.
    /// - Returns: The recorded failing expectation.
    @discardableResult
    public static func record(
        failing message: Swift.String,
        sourceCode: Swift.String,
        at location: Source.Location
    ) -> Self {
        let result = failing(message, sourceCode: sourceCode, at: location)
        Collector.current?.record(result)
        _recordIssue(message, at: location)
        return result
    }
}
