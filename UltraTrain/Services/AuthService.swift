import Foundation
import os

final class AuthService: AuthServiceProtocol, @unchecked Sendable {
    private static let keychainKey = "ultratrain_auth_token"

    private let apiClient: APIClient
    private var token: AuthToken?
    private var refreshTask: Task<AuthToken, Error>?

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        token = try? KeychainManager.load(AuthToken.self, for: Self.keychainKey)
        if token != nil {
            Logger.network.info("Auth: restored session from Keychain")
        }
    }

    func register(email: String, password: String) async throws {
        let response: TokenResponseDTO = try await apiClient.send(
            AuthEndpoints.Register(email: email, password: password)
        )
        let newToken = makeToken(from: response, email: email)
        token = newToken
        try KeychainManager.save(newToken, for: Self.keychainKey)
        Logger.network.info("Auth: registered as \(email)")
    }

    func login(email: String, password: String) async throws {
        let response: TokenResponseDTO = try await apiClient.send(
            AuthEndpoints.Login(email: email, password: password)
        )
        let newToken = makeToken(from: response, email: email)
        token = newToken
        try KeychainManager.save(newToken, for: Self.keychainKey)
        Logger.network.info("Auth: logged in as \(email)")
    }

    func logout() async throws {
        try? await apiClient.sendVoid(AuthEndpoints.Logout())
        clearLocalToken()
        Logger.network.info("Auth: logged out")
    }

    func deleteAccount() async throws {
        try await apiClient.sendVoid(AuthEndpoints.DeleteAccount())
        clearLocalToken()
        Logger.network.info("Auth: account deleted")
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        let _: MessageResponseDTO = try await apiClient.send(
            AuthEndpoints.ChangePassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
        )
    }

    func requestPasswordReset(email: String) async throws {
        let _: MessageResponseDTO = try await apiClient.send(
            AuthEndpoints.ForgotPassword(email: email)
        )
    }

    func resetPassword(email: String, code: String, newPassword: String) async throws {
        let _: MessageResponseDTO = try await apiClient.send(
            AuthEndpoints.ResetPassword(email: email, code: code, newPassword: newPassword)
        )
    }

    func verifyEmail(code: String) async throws {
        let _: MessageResponseDTO = try await apiClient.send(
            AuthEndpoints.VerifyEmail(code: code)
        )
    }

    func resendVerificationCode() async throws {
        let _: MessageResponseDTO = try await apiClient.send(
            AuthEndpoints.ResendVerification()
        )
    }

    func getValidAccessToken() async throws -> String {
        guard var currentToken = token else {
            throw DomainError.unauthorized
        }

        if !currentToken.isExpired {
            return currentToken.accessToken
        }

        currentToken = try await performRefresh(expired: currentToken)
        return currentToken.accessToken
    }

    func isAuthenticated() -> Bool {
        token != nil
    }

    // MARK: - Private

    private func performRefresh(expired: AuthToken) async throws -> AuthToken {
        if let existing = refreshTask {
            return try await existing.value
        }

        let task = Task<AuthToken, Error> { [weak self] in
            guard let self else { throw DomainError.unauthorized }
            defer { self.refreshTask = nil }

            let response: TokenResponseDTO = try await self.apiClient.send(
                AuthEndpoints.Refresh(refreshToken: expired.refreshToken)
            )
            let newToken = self.makeToken(from: response, email: expired.email)
            self.token = newToken
            try KeychainManager.save(newToken, for: Self.keychainKey)
            Logger.network.info("Auth: token refreshed")
            return newToken
        }
        refreshTask = task
        return try await task.value
    }

    private func makeToken(from dto: TokenResponseDTO, email: String) -> AuthToken {
        AuthToken(
            accessToken: dto.accessToken,
            refreshToken: dto.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(dto.expiresIn)),
            userId: "",
            email: email
        )
    }

    private func clearLocalToken() {
        token = nil
        refreshTask = nil
        KeychainManager.delete(for: Self.keychainKey)
    }
}
