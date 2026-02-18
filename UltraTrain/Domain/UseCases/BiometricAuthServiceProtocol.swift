import Foundation

enum BiometricType: Sendable {
    case none
    case touchID
    case faceID
}

protocol BiometricAuthServiceProtocol: Sendable {
    var availableBiometricType: BiometricType { get }
    func authenticate(reason: String) async throws -> Bool
}
