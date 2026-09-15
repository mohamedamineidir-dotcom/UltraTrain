import Vapor

/// Registration endpoint for the marketing website's checkout flow.
///
/// The app's own `/v1/auth/*` routes require an HMAC request signature
/// computed with a secret embedded in the iOS binary — a public static
/// website has nowhere safe to hold that secret, so it cannot call those
/// routes directly. This exposes the exact same registration logic
/// (`AuthController.register`, unchanged) under a separate route that only
/// sits behind rate limiting, not HMAC verification.
struct WebAuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let web = routes.grouped("web")
        web.post("register", use: register)
    }

    @Sendable
    func register(req: Request) async throws -> TokenResponse {
        try await AuthController().register(req: req)
    }
}
