import Foundation

struct AuthToken: Codable, Sendable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
    var userId: String
    var email: String

    // Buffer must comfortably exceed the network layer's request timeout
    // (30s, see AppConfiguration.API.timeoutInterval) — otherwise a
    // request that's slow simply because of what it's doing (e.g.
    // uploading a photo for AI analysis), not because anything is wrong,
    // can pass this check when sent and still cross the token's real,
    // server-side expiry while in flight. The server then rejects it
    // with a 401 that has nothing to do with the token looking "expired"
    // on the client a moment earlier.
    var isExpired: Bool {
        Date() >= expiresAt.addingTimeInterval(-60)
    }
}
