import Foundation
import Testing
@testable import UltraTrain

@Suite("AuthService Tests")
struct AuthServiceTests {

    // MARK: - MockAuthService behavior tests

    private func makeMockAuth(loggedIn: Bool = false, shouldFail: Bool = false) -> MockAuthService {
        let mock = MockAuthService()
        mock.isLoggedIn = loggedIn
        mock.shouldFail = shouldFail
        return mock
    }

    // MARK: - Registration

    @Test("register succeeds and sets authenticated state")
    func registerSucceeds() async throws {
        let auth = makeMockAuth()

        try await auth.register(email: "runner@ultra.com", password: "S3cureP@ss!")

        #expect(auth.isAuthenticated() == true)
        #expect(auth.registerCallCount == 1)
        #expect(auth.lastEmail == "runner@ultra.com")
    }

    @Test("register throws on server failure")
    func registerThrowsOnFailure() async {
        let auth = makeMockAuth(shouldFail: true)

        await #expect(throws: DomainError.self) {
            try await auth.register(email: "fail@test.com", password: "password")
        }
        #expect(auth.isAuthenticated() == false)
    }

    // MARK: - Login

    @Test("login succeeds and marks as authenticated")
    func loginSucceeds() async throws {
        let auth = makeMockAuth()

        try await auth.login(email: "user@test.com", password: "password123")

        #expect(auth.isAuthenticated() == true)
        #expect(auth.loginCallCount == 1)
        #expect(auth.lastEmail == "user@test.com")
    }

    @Test("login throws unauthorized on failure")
    func loginThrowsOnFailure() async {
        let auth = makeMockAuth(shouldFail: true)

        await #expect(throws: DomainError.unauthorized) {
            try await auth.login(email: "bad@test.com", password: "wrong")
        }
    }

    // MARK: - Logout

    @Test("logout clears authenticated state")
    func logoutClearsState() async throws {
        let auth = makeMockAuth(loggedIn: true)

        try await auth.logout()

        #expect(auth.isAuthenticated() == false)
        #expect(auth.logoutCallCount == 1)
    }

    // MARK: - Delete Account

    @Test("deleteAccount clears session")
    func deleteAccountClearsSession() async throws {
        let auth = makeMockAuth(loggedIn: true)

        try await auth.deleteAccount()

        #expect(auth.isAuthenticated() == false)
        #expect(auth.deleteAccountCallCount == 1)
    }

    // MARK: - Token Access

    @Test("getValidAccessToken returns token when authenticated")
    func getTokenWhenAuthenticated() async throws {
        let auth = makeMockAuth(loggedIn: true)

        let token = try await auth.getValidAccessToken()

        #expect(token == "mock-token")
    }

    @Test("getValidAccessToken throws unauthorized when not logged in")
    func getTokenThrowsWhenNotAuthenticated() async {
        let auth = makeMockAuth(loggedIn: false)

        await #expect(throws: DomainError.unauthorized) {
            try await auth.getValidAccessToken()
        }
    }

    // MARK: - isAuthenticated

    @Test("isAuthenticated reflects login state")
    func isAuthenticatedReflectsState() {
        let auth = makeMockAuth(loggedIn: false)
        #expect(auth.isAuthenticated() == false)

        auth.isLoggedIn = true
        #expect(auth.isAuthenticated() == true)
    }

    // MARK: - Change Password

    @Test("changePassword increments call count on success")
    func changePasswordSucceeds() async throws {
        let auth = makeMockAuth(loggedIn: true)

        try await auth.changePassword(currentPassword: "old", newPassword: "new")

        #expect(auth.changePasswordCallCount == 1)
    }

    @Test("changePassword throws on failure")
    func changePasswordThrowsOnFailure() async {
        let auth = makeMockAuth(shouldFail: true)

        await #expect(throws: DomainError.self) {
            try await auth.changePassword(currentPassword: "old", newPassword: "new")
        }
    }

    // MARK: - Password Reset

    @Test("requestPasswordReset sends email")
    func requestPasswordReset() async throws {
        let auth = makeMockAuth()

        try await auth.requestPasswordReset(email: "forgot@test.com")

        #expect(auth.requestPasswordResetCallCount == 1)
        #expect(auth.lastEmail == "forgot@test.com")
    }

    @Test("resetPassword completes successfully")
    func resetPasswordSucceeds() async throws {
        let auth = makeMockAuth()

        try await auth.resetPassword(email: "user@test.com", code: "123456", newPassword: "newPass!")

        #expect(auth.resetPasswordCallCount == 1)
    }

    // MARK: - Email Verification

    @Test("verifyEmail increments call count")
    func verifyEmailSucceeds() async throws {
        let auth = makeMockAuth()

        try await auth.verifyEmail(code: "654321")

        #expect(auth.verifyEmailCallCount == 1)
    }

    @Test("resendVerificationCode increments call count")
    func resendVerificationSucceeds() async throws {
        let auth = makeMockAuth()

        try await auth.resendVerificationCode()

        #expect(auth.resendVerificationCallCount == 1)
    }

    // MARK: - AuthToken model

    @Test("AuthToken isExpired returns false for future expiry")
    func tokenNotExpiredForFutureDate() {
        let token = AuthToken(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(3600),
            userId: "user1",
            email: "test@test.com"
        )

        #expect(token.isExpired == false)
    }

    @Test("AuthToken isExpired returns true for past expiry")
    func tokenExpiredForPastDate() {
        let token = AuthToken(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(-60),
            userId: "user1",
            email: "test@test.com"
        )

        #expect(token.isExpired == true)
    }

    @Test("AuthToken isExpired returns true within 30-second buffer")
    func tokenExpiredWithinBuffer() {
        let token = AuthToken(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(20),
            userId: "user1",
            email: "test@test.com"
        )

        // Token has 20s left, but the 30s buffer means it should be considered expired
        #expect(token.isExpired == true)
    }
}
