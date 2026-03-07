import Foundation

protocol AuthServiceProtocol: Sendable {
    func register(email: String, password: String, firstName: String?, referralCode: String?) async throws
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

    /// Returns `true` if the user is new (needs onboarding).
    func signInWithApple(identityToken: String, firstName: String?, lastName: String?) async throws -> Bool
    /// Returns `true` if the user is new (needs onboarding).
    func signInWithGoogle(idToken: String) async throws -> Bool
}
