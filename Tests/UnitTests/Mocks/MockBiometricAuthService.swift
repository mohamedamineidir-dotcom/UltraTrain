import Foundation
@testable import UltraTrain

final class MockBiometricAuthService: BiometricAuthServiceProtocol, @unchecked Sendable {
    var biometricType: BiometricType = .faceID
    var shouldSucceed = true
    var shouldThrow = false
    var authenticateCalled = false

    var availableBiometricType: BiometricType { biometricType }

    func authenticate(reason: String) async throws -> Bool {
        authenticateCalled = true
        if shouldThrow { throw DomainError.biometricFailed(reason: "Mock error") }
        return shouldSucceed
    }
}
