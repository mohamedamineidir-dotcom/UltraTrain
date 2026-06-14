import Vapor

/// Server-side Strava OAuth token exchange/refresh. The Strava client secret
/// lives ONLY here (Railway env `STRAVA_CLIENT_SECRET`) so it never ships in
/// the iOS app. The app still performs the user-facing authorize step (which
/// only needs the public client_id) and sends us the resulting code.
struct StravaIntegrationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let strava = routes.grouped("integrations", "strava")
            .grouped(UserAuthMiddleware())
        strava.post("exchange", use: exchange)
        strava.post("refresh", use: refresh)
    }

    // MARK: - DTOs

    struct ExchangeRequest: Content { let code: String }
    struct RefreshRequest: Content { let refreshToken: String }

    struct TokenResponse: Content {
        let accessToken: String
        let refreshToken: String
        let expiresAt: Int
        let athleteId: Int?
        let athleteName: String?
    }

    // MARK: - Handlers

    @Sendable
    func exchange(req: Request) async throws -> TokenResponse {
        _ = try req.userId
        let input = try req.content.decode(ExchangeRequest.self)
        guard !input.code.isEmpty else { throw Abort(.badRequest, reason: "Missing code.") }
        return try await callStravaToken(req: req, params: [
            "code": input.code,
            "grant_type": "authorization_code"
        ])
    }

    @Sendable
    func refresh(req: Request) async throws -> TokenResponse {
        _ = try req.userId
        let input = try req.content.decode(RefreshRequest.self)
        guard !input.refreshToken.isEmpty else { throw Abort(.badRequest, reason: "Missing refresh token.") }
        return try await callStravaToken(req: req, params: [
            "refresh_token": input.refreshToken,
            "grant_type": "refresh_token"
        ])
    }

    // MARK: - Strava call

    private func callStravaToken(req: Request, params: [String: String]) async throws -> TokenResponse {
        guard let clientId = Environment.get("STRAVA_CLIENT_ID"),
              let clientSecret = Environment.get("STRAVA_CLIENT_SECRET"),
              !clientId.isEmpty, !clientSecret.isEmpty else {
            req.logger.error("StravaIntegration: STRAVA_CLIENT_ID/SECRET not configured")
            throw Abort(.serviceUnavailable, reason: "Strava integration is temporarily unavailable.")
        }

        var body = params
        body["client_id"] = clientId
        body["client_secret"] = clientSecret
        let bodyData = try JSONSerialization.data(withJSONObject: body)

        let response = try await req.client.post("https://www.strava.com/oauth/token") { out in
            out.headers.contentType = .json
            out.body = ByteBuffer(data: bodyData)
        }

        guard response.status == .ok, let buffer = response.body else {
            let detail = response.body.map { String(buffer: $0) } ?? "no body"
            req.logger.error("StravaIntegration: token call failed \(response.status.code): \(detail)")
            throw Abort(.badGateway, reason: "Strava authorization failed. Please try again.")
        }

        return try parse(Data(buffer: buffer))
    }

    private func parse(_ data: Data) throws -> TokenResponse {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let access = json["access_token"] as? String,
              let refresh = json["refresh_token"] as? String,
              let expiresAt = json["expires_at"] as? Int else {
            throw Abort(.badGateway, reason: "Strava authorization failed. Please try again.")
        }
        let athlete = json["athlete"] as? [String: Any]
        let athleteId = athlete?["id"] as? Int
        let athleteName: String?
        if let athlete {
            let first = athlete["firstname"] as? String ?? ""
            let last = athlete["lastname"] as? String ?? ""
            let combined = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
            athleteName = combined.isEmpty ? nil : combined
        } else {
            athleteName = nil
        }
        return TokenResponse(
            accessToken: access,
            refreshToken: refresh,
            expiresAt: expiresAt,
            athleteId: athleteId,
            athleteName: athleteName
        )
    }
}
