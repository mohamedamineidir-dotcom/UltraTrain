import Foundation
import AuthenticationServices
import os

// @unchecked Sendable: token mutated only via async methods (no races)
final class StravaAuthService: StravaAuthServiceProtocol, @unchecked Sendable {
    private static let logger = Logger.strava
    private static let keychainKey = "strava_token"

    private var token: StravaToken?
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        do {
            token = try KeychainManager.load(StravaToken.self, for: Self.keychainKey)
        } catch {
            token = nil
            Self.logger.warning("Strava: failed to load token from Keychain: \(error)")
        }
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

        // invariant: authorizeURL is a compile-time constant string
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

            Task { @MainActor in session.start() }
        }
    }

    // MARK: - Token Exchange

    private func exchangeCodeForToken(_ code: String) async throws -> StravaToken {
        // The backend holds the client secret and performs the exchange.
        do {
            let dto = try await apiClient.send(StravaEndpoints.Exchange(code: code))
            return makeToken(from: dto)
        } catch {
            Self.logger.error("Strava token exchange failed: \(error.localizedDescription)")
            throw DomainError.stravaAuthFailed(reason: "Token exchange failed")
        }
    }

    // MARK: - Token Refresh

    private func refreshToken(_ expiredToken: StravaToken) async throws -> StravaToken {
        do {
            let dto = try await apiClient.send(StravaEndpoints.Refresh(refreshToken: expiredToken.refreshToken))
            Self.logger.info("Strava: token refreshed")
            return makeToken(from: dto)
        } catch {
            Self.logger.error("Strava token refresh failed: \(error.localizedDescription)")
            throw DomainError.stravaAuthFailed(reason: "Token refresh failed")
        }
    }

    // MARK: - Response Mapping

    private func makeToken(from dto: StravaTokenDTO) -> StravaToken {
        // `athlete*` are only present on the initial exchange, not on refresh —
        // fall back to the stored token so a refresh keeps the athlete identity.
        let athleteName = dto.athleteName ?? token?.athleteName ?? "Strava Athlete"
        let athleteId = dto.athleteId ?? token?.athleteId ?? 0

        return StravaToken(
            accessToken: dto.accessToken,
            refreshToken: dto.refreshToken,
            expiresAt: Date(timeIntervalSince1970: TimeInterval(dto.expiresAt)),
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
