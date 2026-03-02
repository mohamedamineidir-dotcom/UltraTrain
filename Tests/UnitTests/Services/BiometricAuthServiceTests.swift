import Foundation
import Testing
@testable import UltraTrain

@Suite("BiometricAuthService Tests")
struct BiometricAuthServiceTests {

    // MARK: - Helpers

    private func makeMock(
        biometricType: BiometricType = .faceID,
        shouldSucceed: Bool = true,
        shouldThrow: Bool = false
    ) -> MockBiometricAuthService {
        let mock = MockBiometricAuthService()
        mock.biometricType = biometricType
        mock.shouldSucceed = shouldSucceed
        mock.shouldThrow = shouldThrow
        return mock
    }

    // MARK: - availableBiometricType

    @Test("availableBiometricType returns faceID when configured")
    func availableBiometricTypeFaceID() {
        let service = makeMock(biometricType: .faceID)
        #expect(service.availableBiometricType == .faceID)
    }

    @Test("availableBiometricType returns touchID when configured")
    func availableBiometricTypeTouchID() {
        let service = makeMock(biometricType: .touchID)
        #expect(service.availableBiometricType == .touchID)
    }

    @Test("availableBiometricType returns none when unavailable")
    func availableBiometricTypeNone() {
        let service = makeMock(biometricType: .none)
        #expect(service.availableBiometricType == .none)
    }

    // MARK: - authenticate

    @Test("authenticate returns true on success")
    func authenticateSuccess() async throws {
        let service = makeMock(shouldSucceed: true)

        let result = try await service.authenticate(reason: "Unlock app")

        #expect(result == true)
        #expect(service.authenticateCalled == true)
    }

    @Test("authenticate returns false when biometric fails without throwing")
    func authenticateReturnsFalse() async throws {
        let service = makeMock(shouldSucceed: false, shouldThrow: false)

        let result = try await service.authenticate(reason: "Unlock app")

        #expect(result == false)
        #expect(service.authenticateCalled == true)
    }

    @Test("authenticate throws biometricFailed error when shouldThrow is true")
    func authenticateThrowsError() async {
        let service = makeMock(shouldThrow: true)

        await #expect(throws: DomainError.self) {
            try await service.authenticate(reason: "Access health data")
        }
        #expect(service.authenticateCalled == true)
    }

    @Test("authenticate sets authenticateCalled flag")
    func authenticateSetsCalled() async throws {
        let service = makeMock()

        #expect(service.authenticateCalled == false)
        _ = try await service.authenticate(reason: "Test")
        #expect(service.authenticateCalled == true)
    }
}
