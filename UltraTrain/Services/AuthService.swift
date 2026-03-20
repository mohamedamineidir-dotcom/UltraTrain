import Foundation
import os

// @unchecked Sendable: token mutated only via async methods (no races)
final class AuthService: AuthServiceProtocol, @unchecked Sendable {
    private static let keychainKey = "ultratrain_auth_token"

    private let apiClient: APIClient
    private var token: AuthToken?
    private var refreshTask: Task<AuthToken, Error>?

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        do {
            token = try KeychainManager.load(AuthToken.self, for: Self.keychainKey)
        } catch {
            token = nil
            Logger.network.warning("Auth: failed to load token from Keychain: \(error)")
        }
        if token != nil {
            Logger.network.info("Auth: restored session from Keychain")
        }
    }

    func register(email: String, password: String, firstName: String? = nil, referralCode: String? = nil) async throws {
        let response: TokenResponseDTO = try await apiClient.send(
            AuthEndpoints.Register(
                email: email, password: password,
                firstName: firstName, referralCode: referralCode
            )
        )
        let newToken = makeToken(from: response, email: email)
        token = newToken
        try KeychainManager.save(newToken, for: Self.keychainKey)
        Logger.network.info("Auth: registered as \(email)")
    }

    func signInWithApple(identityToken: String, firstName: String?, lastName: String?) async throws -> Bool {
        let response: SocialAuthResponseDTO = try await apiClient.send(
            AuthEndpoints.AppleSignIn(
                identityToken: identityToken,
                firstName: firstName, lastName: lastName
            )
        )
        let newToken = makeSocialToken(from: response)
        token = newToken
        try KeychainManager.save(newToken, for: Self.keychainKey)
        Logger.network.info("Auth: signed in with Apple (isNew: \(response.isNewUser))")
        return response.isNewUser
    }

    func signInWithGoogle(idToken: String) async throws -> Bool {
        let response: SocialAuthResponseDTO = try await apiClient.send(
            AuthEndpoints.GoogleSignIn(idToken: idToken)
        )
        let newToken = makeSocialToken(from: response)
        token = newToken
        try KeychainManager.save(newToken, for: Self.keychainKey)
        Logger.network.info("Auth: signed in with Google (isNew: \(response.isNewUser))")
        return response.isNewUser
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
        do {
            try await apiClient.sendVoid(AuthEndpoints.Logout())
        } catch {
            Logger.network.warning("Auth: server logout request failed (clearing local token anyway): \(error)")
        }
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

    func clearLocalSession() {
        clearLocalToken()
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

    private func makeSocialToken(from dto: SocialAuthResponseDTO) -> AuthToken {
        AuthToken(
            accessToken: dto.accessToken,
            refreshToken: dto.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(dto.expiresIn)),
            userId: "",
            email: ""
        )
    }

    private func clearLocalToken() {
        token = nil
        refreshTask = nil
        KeychainManager.delete(for: Self.keychainKey)
    }
}
