import AuthenticationServices
import Foundation
import os

protocol SuuntoAuthServiceProtocol: Sendable {
    func authenticate() async throws
    func getValidToken() async throws -> String
    func disconnect() async
    var isConnected: Bool { get }
}

final class SuuntoAuthService: SuuntoAuthServiceProtocol, @unchecked Sendable {
    private let logger = Logger(subsystem: "com.ultratrain", category: "suunto")
    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiry: Date = .distantPast

    private var clientId: String { AppConfiguration.suuntoClientId }
    private var clientSecret: String { AppConfiguration.suuntoClientSecret }
    private let redirectURI = "ultratrain://suunto-callback"
    private let keychainKey = "suunto_tokens"

    var isConnected: Bool { accessToken != nil }

    func authenticate() async throws {
        let code = try await performOAuth()
        try await exchangeCodeForToken(code: code)
        logger.info("Suunto authenticated successfully")
    }

    func disconnect() async {
        accessToken = nil
        refreshToken = nil
        tokenExpiry = .distantPast
        KeychainManager.delete(for: keychainKey)
        logger.info("Suunto disconnected")
    }

    func getValidToken() async throws -> String {
        if let token = accessToken, tokenExpiry > Date() {
            return token
        }
        if let saved = loadTokens(), saved.expiry > Date() {
            accessToken = saved.access
            refreshToken = saved.refresh
            tokenExpiry = saved.expiry
            return saved.access
        }
        if let saved = loadTokens(), let refresh = saved.refresh {
            try await refreshAccessToken(refresh)
            return accessToken ?? ""
        }
        throw SuuntoError.notAuthenticated
    }

    // MARK: - OAuth Flow

    private func performOAuth() async throws -> String {
        var components = URLComponents(string: "https://cloudapi-oauth.suunto.com/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
        ]

        let url = components.url!
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "ultratrain"
            ) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callbackURL,
                      let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                          .queryItems?.first(where: { $0.name == "code" })?.value
                else {
                    continuation.resume(throwing: SuuntoError.noAuthCode)
                    return
                }
                continuation.resume(returning: code)
            }
            session.presentationContextProvider = SuuntoOAuthProvider.shared
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }

    // MARK: - Token Exchange

    private func exchangeCodeForToken(code: String) async throws {
        var request = URLRequest(url: URL(string: "https://cloudapi-oauth.suunto.com/oauth/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var body = "grant_type=authorization_code"
        body += "&code=\(code)"
        body += "&client_id=\(clientId)"
        body += "&client_secret=\(clientSecret)"
        body += "&redirect_uri=\(redirectURI)"
        request.httpBody = body.data(using: .utf8)
        defer { request.httpBody = nil }

        let (data, _) = try await URLSession.shared.data(for: request)
        try parseAndSaveTokens(data)
    }

    private func refreshAccessToken(_ token: String) async throws {
        var request = URLRequest(url: URL(string: "https://cloudapi-oauth.suunto.com/oauth/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var body = "grant_type=refresh_token"
        body += "&refresh_token=\(token)"
        body += "&client_id=\(clientId)"
        body += "&client_secret=\(clientSecret)"
        request.httpBody = body.data(using: .utf8)
        defer { request.httpBody = nil }

        let (data, _) = try await URLSession.shared.data(for: request)
        try parseAndSaveTokens(data)
    }

    // MARK: - Token Parsing

    private func parseAndSaveTokens(_ data: Data) throws {
        let response = try JSONDecoder().decode(TokenResponse.self, from: data)
        accessToken = response.accessToken
        refreshToken = response.refreshToken
        tokenExpiry = Date().addingTimeInterval(TimeInterval(response.expiresIn))
        saveTokens()
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String?
        let expiresIn: Int
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
        }
    }

    // MARK: - Keychain

    private struct SavedTokens: Codable {
        let access: String
        let refresh: String?
        let expiry: Date
    }

    private func saveTokens() {
        let saved = SavedTokens(access: accessToken ?? "", refresh: refreshToken, expiry: tokenExpiry)
        if let data = try? JSONEncoder().encode(saved) {
            try? KeychainManager.save(data, for: keychainKey)
        }
    }

    private func loadTokens() -> SavedTokens? {
        guard let data = try? KeychainManager.load(for: keychainKey) else { return nil }
        return try? JSONDecoder().decode(SavedTokens.self, from: data)
    }
}

enum SuuntoError: Error, LocalizedError {
    case notAuthenticated
    case noAuthCode

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: "Not authenticated with Suunto. Please connect your account."
        case .noAuthCode: "Failed to receive authorization code from Suunto."
        }
    }
}

private final class SuuntoOAuthProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = SuuntoOAuthProvider()
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}
