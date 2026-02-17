import Foundation

struct StravaToken: Codable, Sendable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
    var athleteId: Int
    var athleteName: String

    var isExpired: Bool {
        Date() >= expiresAt
    }
}
