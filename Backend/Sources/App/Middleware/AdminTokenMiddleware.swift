import Vapor

/// Protects admin endpoints with a static bearer token from the ADMIN_TOKEN environment variable.
struct AdminTokenMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let expectedToken = Environment.get("ADMIN_TOKEN"), !expectedToken.isEmpty else {
            throw Abort(.serviceUnavailable, reason: "Admin access not configured")
        }

        guard let bearer = request.headers.bearerAuthorization else {
            throw Abort(.unauthorized, reason: "Missing authorization header")
        }

        guard bearer.token == expectedToken else {
            throw Abort(.forbidden, reason: "Invalid admin token")
        }

        return try await next.respond(to: request)
    }
}
