import Foundation
@testable import UltraTrain

final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    var shouldFail = false
    var registeredEmail: String?
    var isLoggedIn = false

    var registerCallCount = 0
    var loginCallCount = 0
    var logoutCallCount = 0
    var deleteAccountCallCount = 0

    var lastEmail: String?
    var lastPassword: String?

    func register(email: String, password: String) async throws {
        registerCallCount += 1
        lastEmail = email
        lastPassword = password
        if shouldFail {
            throw DomainError.serverError(message: "Registration failed")
        }
        registeredEmail = email
        isLoggedIn = true
    }

    func login(email: String, password: String) async throws {
        loginCallCount += 1
        lastEmail = email
        lastPassword = password
        if shouldFail {
            throw DomainError.unauthorized
        }
        isLoggedIn = true
    }

    func logout() async throws {
        logoutCallCount += 1
        if shouldFail {
            throw DomainError.serverError(message: "Logout failed")
        }
        isLoggedIn = false
    }

    func deleteAccount() async throws {
        deleteAccountCallCount += 1
        if shouldFail {
            throw DomainError.serverError(message: "Delete account failed")
        }
        isLoggedIn = false
    }

    var changePasswordCallCount = 0
    var requestPasswordResetCallCount = 0
    var resetPasswordCallCount = 0

    func changePassword(currentPassword: String, newPassword: String) async throws {
        changePasswordCallCount += 1
        if shouldFail {
            throw DomainError.serverError(message: "Change password failed")
        }
    }

    func requestPasswordReset(email: String) async throws {
        requestPasswordResetCallCount += 1
        lastEmail = email
        if shouldFail {
            throw DomainError.serverError(message: "Reset failed")
        }
    }

    func resetPassword(email: String, code: String, newPassword: String) async throws {
        resetPasswordCallCount += 1
        lastEmail = email
        if shouldFail {
            throw DomainError.serverError(message: "Reset failed")
        }
    }

    func getValidAccessToken() async throws -> String {
        guard isLoggedIn else {
            throw DomainError.unauthorized
        }
        return "mock-token"
    }

    func isAuthenticated() -> Bool {
        isLoggedIn
    }
}
