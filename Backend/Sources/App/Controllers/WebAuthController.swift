import Vapor

/// Registration and login endpoints for the marketing website (checkout
/// flow, and later a "manage subscription" page).
///
/// The app's own `/v1/auth/*` routes require an HMAC request signature
/// computed with a secret embedded in the iOS binary — a public static
/// website has nowhere safe to hold that secret, so it cannot call those
/// routes directly. This exposes the exact same auth logic
/// (`AuthController.register`/`login`, unchanged) under separate routes
/// that only sit behind rate limiting, not HMAC verification.
struct WebAuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let web = routes.grouped("web")
        web.post("register", use: register)
        web.post("login", use: login)
    }

    @Sendable
    func register(req: Request) async throws -> TokenResponse {
        try await AuthController().register(req: req)
    }

    @Sendable
    func login(req: Request) async throws -> TokenResponse {
        try await AuthController().login(req: req)
    }
}
