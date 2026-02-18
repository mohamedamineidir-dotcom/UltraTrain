import LocalAuthentication
import os

final class BiometricAuthService: BiometricAuthServiceProtocol, @unchecked Sendable {

    var availableBiometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .faceID
        case .none: return .none
        @unknown default: return .none
        }
    }

    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            Logger.biometric.info("Biometric auth result: \(success)")
            return success
        } catch {
            Logger.biometric.error("Biometric auth failed: \(error)")
            throw DomainError.biometricFailed(reason: error.localizedDescription)
        }
    }
}
