import Foundation

struct AuthToken: Codable, Sendable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
    var userId: String
    var email: String

    var isExpired: Bool {
        Date() >= expiresAt.addingTimeInterval(-30)
    }
}
