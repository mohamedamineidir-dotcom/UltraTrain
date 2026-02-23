import Foundation

protocol AuthServiceProtocol: Sendable {
    func register(email: String, password: String) async throws
    func login(email: String, password: String) async throws
    func logout() async throws
    func getValidAccessToken() async throws -> String
    func deleteAccount() async throws
    func changePassword(currentPassword: String, newPassword: String) async throws
    func requestPasswordReset(email: String) async throws
    func resetPassword(email: String, code: String, newPassword: String) async throws
    func verifyEmail(code: String) async throws
    func resendVerificationCode() async throws
    func isAuthenticated() -> Bool
}
