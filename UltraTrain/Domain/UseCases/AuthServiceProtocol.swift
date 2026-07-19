import Foundation

protocol AuthServiceProtocol: Sendable {
    func register(email: String, password: String, firstName: String?, referralCode: String?) async throws
    func login(email: String, password: String) async throws
    func logout() async throws
    func getValidAccessToken() async throws -> String
    /// Refreshes the access token unconditionally, even if the locally
    /// cached token doesn't look expired yet. Used when the SERVER has
    /// already rejected the current token with a 401 — trusting the
    /// server's verdict over a local expiry clock that can disagree with
    /// it (e.g. a slow request, like a food-photo upload, that was valid
    /// when sent but crosses the token's expiry while in flight).
    func forceRefreshAccessToken() async throws -> String
    func deleteAccount() async throws
    func changePassword(currentPassword: String, newPassword: String) async throws
    func requestPasswordReset(email: String) async throws
    func resetPassword(email: String, code: String, newPassword: String) async throws
    func verifyEmail(code: String) async throws
    func resendVerificationCode() async throws
    func isAuthenticated() -> Bool

    /// Clears local auth tokens without contacting the server.
    /// Used on fresh install to wipe stale Keychain data.
    func clearLocalSession()

    /// Returns whether the user is new (needs onboarding), plus the name on
    /// file for the account. The name is the one persisted server-side from
    /// whichever authorization first supplied it — present even when this
    /// particular Apple credential didn't include a fresh one (Apple only
    /// includes it on the very first authorization for a given Apple ID).
    func signInWithApple(identityToken: String, firstName: String?, lastName: String?) async throws -> SocialSignInResult
    /// Returns whether the user is new (needs onboarding), plus the name on file.
    func signInWithGoogle(idToken: String) async throws -> SocialSignInResult
}

struct SocialSignInResult: Sendable {
    let isNewUser: Bool
    let firstName: String?
    let lastName: String?
}
