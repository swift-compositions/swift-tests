//
//  Test.Environment+JSON.swift
//  swift-tests
//
//  JSON.Serializable conformance for Test.Environment.
//

import Cardinal
public import JSON
public import Kernel
import Tagged
import Time

extension Test.Environment: JSON.Serializable {
    /// Serializes the environment as a JSON object.
    ///
    /// Used to write an `environment.json` alongside baselines
    /// for human inspection and debugging.
    public static func serialize(_ value: Self) -> JSON {
        guard let memoryBytes = Int(exactly: value.memoryBytes.rawValue) else {
            preconditionFailure("Memory capacity is not representable as a JSON Int")
        }
        precondition(value.physicalCPUCount >= 0 && value.logicalCPUCount >= 0,
                     "CPU counts must be nonnegative")
        let features: JSON = .object([
            (
                "NonisolatedNonsendingByDefault",
                JSON.bool(value.features.nonisolatedNonsendingByDefault)
            ),
            ("StrictMemorySafety", JSON.bool(value.features.strictMemorySafety)),
        ])

        return .object([
            ("architecture", JSON.string(value.architecture)),
            (
                "physical_cores",
                JSON.number(value.physicalCPUCount)
            ),
            (
                "logical_cores",
                JSON.number(value.logicalCPUCount)
            ),
            ("memory_bytes", JSON.number(memoryBytes)),
            ("os", JSON.string(value.osVersion)),
            ("swift_version", JSON.string(value.swiftVersion)),
            ("optimization", JSON.string(value.optimization.rawValue)),
            ("features", features),
            ("fingerprint", JSON.string(value.fingerprint)),
        ])
    }

    /// Deserializes an environment from JSON.
    public static func deserialize(_ json: JSON) throws(JSON.Error) -> Self {
        let architecture: Swift.String
        do throws(JSON.Error) {
            architecture = try Swift.String(json: json.architecture)
        } catch {
            throw .missingKey("architecture")
        }
        let physicalCores: Int
        do throws(JSON.Error) {
            physicalCores = try Int(json: json.physical_cores)
        } catch {
            throw .missingKey("physical_cores")
        }
        let logicalCores: Int
        do throws(JSON.Error) {
            logicalCores = try Int(json: json.logical_cores)
        } catch {
            throw .missingKey("logical_cores")
        }
        let memoryBytes: Int
        do throws(JSON.Error) {
            memoryBytes = try Int(json: json.memory_bytes)
        } catch {
            throw .missingKey("memory_bytes")
        }
        let os: Swift.String
        do throws(JSON.Error) {
            os = try Swift.String(json: json.os)
        } catch {
            throw .missingKey("os")
        }
        let swiftVersion: Swift.String
        do throws(JSON.Error) {
            swiftVersion = try Swift.String(json: json.swift_version)
        } catch {
            throw .missingKey("swift_version")
        }
        let optimization: Swift.String
        do throws(JSON.Error) {
            optimization = try Swift.String(json: json.optimization)
        } catch {
            throw .missingKey("optimization")
        }

        let nnbd: Bool
        do throws(JSON.Error) {
            nnbd = try Bool(json: json.features.NonisolatedNonsendingByDefault)
        } catch {
            nnbd = false
        }
        let sms: Bool
        do throws(JSON.Error) {
            sms = try Bool(json: json.features.StrictMemorySafety)
        } catch {
            sms = false
        }

        guard physicalCores >= 0, logicalCores >= 0,
              let unsignedMemoryBytes = UInt(exactly: memoryBytes) else {
            throw .typeMismatch(expected: "nonnegative hardware counts", got: "negative value")
        }

        return Self(
            architecture: architecture,
            physicalCPUCount: physicalCores,
            logicalCPUCount: logicalCores,
            memoryBytes: Cardinal(unsignedMemoryBytes),
            osVersion: os,
            swiftVersion: swiftVersion,
            optimization: .init(rawValue: optimization),
            features: .init(
                nonisolatedNonsendingByDefault: nnbd,
                strictMemorySafety: sms
            )
        )
    }
}
