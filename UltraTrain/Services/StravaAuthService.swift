import Foundation
import AuthenticationServices
import os

final class StravaAuthService: StravaAuthServiceProtocol, @unchecked Sendable {
    private static let logger = Logger.strava
    private static let keychainKey = "strava_token"

    private var token: StravaToken?

    init() {
        token = try? KeychainManager.load(StravaToken.self, for: Self.keychainKey)
        if let name = token?.athleteName {
            Self.logger.info("Strava: restored session for \(name)")
        }
    }

    // MARK: - StravaAuthServiceProtocol

    func authenticate() async throws {
        let config = AppConfiguration.Strava.self
        guard !config.clientId.isEmpty else {
            throw DomainError.stravaAuthFailed(reason: "Strava API credentials not configured")
        }

        let code = try await performOAuth()
        let newToken = try await exchangeCodeForToken(code)

        token = newToken
        try KeychainManager.save(newToken, for: Self.keychainKey)
        Self.logger.info("Strava: authenticated as \(newToken.athleteName)")
    }

    func disconnect() {
        token = nil
        KeychainManager.delete(for: Self.keychainKey)
        Self.logger.info("Strava: disconnected")
    }

    func getValidToken() async throws -> String {
        guard var currentToken = token else {
            throw DomainError.stravaAuthFailed(reason: "Not connected to Strava")
        }

        if currentToken.isExpired {
            currentToken = try await refreshToken(currentToken)
            token = currentToken
            try KeychainManager.save(currentToken, for: Self.keychainKey)
        }

        return currentToken.accessToken
    }

    func isConnected() -> Bool {
        token != nil
    }

    func getConnectionStatus() -> StravaConnectionStatus {
        if let token {
            return .connected(athleteName: token.athleteName)
        }
        return .disconnected
    }

    func getAthleteName() -> String? {
        token?.athleteName
    }

    // MARK: - OAuth Flow

    private func performOAuth() async throws -> String {
        let config = AppConfiguration.Strava.self

        var components = URLComponents(string: config.authorizeURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: "\(config.callbackURLScheme)://\(config.callbackURLScheme)"),
            URLQueryItem(name: "scope", value: config.requiredScopes),
            URLQueryItem(name: "approval_prompt", value: "auto")
        ]

        guard let authURL = components.url else {
            throw DomainError.stravaAuthFailed(reason: "Invalid authorization URL")
        }

        let provider = await MainActor.run { OAuthPresentationProvider.shared }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: config.callbackURLScheme
            ) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: DomainError.stravaAuthFailed(
                        reason: error.localizedDescription
                    ))
                    return
                }

                guard let callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                      let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: DomainError.stravaAuthFailed(
                        reason: "No authorization code received"
                    ))
                    return
                }

                continuation.resume(returning: code)
            }

            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = provider

            DispatchQueue.main.async {
                session.start()
            }
        }
    }

    // MARK: - Token Exchange

    private func exchangeCodeForToken(_ code: String) async throws -> StravaToken {
        let config = AppConfiguration.Strava.self

        var request = URLRequest(url: URL(string: config.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "client_id": config.clientId,
            "client_secret": config.clientSecret,
            "code": code,
            "grant_type": "authorization_code"
        ]
        var httpBody = try JSONEncoder().encode(body)
        request.httpBody = httpBody
        defer { httpBody.resetBytes(in: 0..<httpBody.count) }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            Self.logger.error("Strava token exchange failed")
            throw DomainError.stravaAuthFailed(reason: "Token exchange failed")
        }

        return try parseTokenResponse(data)
    }

    // MARK: - Token Refresh

    private func refreshToken(_ expiredToken: StravaToken) async throws -> StravaToken {
        let config = AppConfiguration.Strava.self

        var request = URLRequest(url: URL(string: config.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "client_id": config.clientId,
            "client_secret": config.clientSecret,
            "refresh_token": expiredToken.refreshToken,
            "grant_type": "refresh_token"
        ]
        var httpBody = try JSONEncoder().encode(body)
        request.httpBody = httpBody
        defer { httpBody.resetBytes(in: 0..<httpBody.count) }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            Self.logger.error("Strava token refresh failed")
            throw DomainError.stravaAuthFailed(reason: "Token refresh failed")
        }

        Self.logger.info("Strava: token refreshed")
        return try parseTokenResponse(data)
    }

    // MARK: - Response Parsing

    private func parseTokenResponse(_ data: Data) throws -> StravaToken {
        struct TokenResponse: Decodable {
            let accessToken: String
            let refreshToken: String
            let expiresAt: Int
            let athlete: Athlete?

            struct Athlete: Decodable {
                let id: Int
                let firstname: String
                let lastname: String
            }

            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case refreshToken = "refresh_token"
                case expiresAt = "expires_at"
                case athlete
            }
        }

        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        let athleteName = decoded.athlete.map { "\($0.firstname) \($0.lastname)" }
            ?? token?.athleteName ?? "Strava Athlete"
        let athleteId = decoded.athlete?.id ?? token?.athleteId ?? 0

        return StravaToken(
            accessToken: decoded.accessToken,
            refreshToken: decoded.refreshToken,
            expiresAt: Date(timeIntervalSince1970: TimeInterval(decoded.expiresAt)),
            athleteId: athleteId,
            athleteName: athleteName
        )
    }
}

// MARK: - Presentation Context Provider

@MainActor
private final class OAuthPresentationProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = OAuthPresentationProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}
