import Foundation

struct StravaExchangeRequestDTO: Encodable, Sendable {
    let code: String
}

struct StravaRefreshRequestDTO: Encodable, Sendable {
    let refreshToken: String
}

struct StravaTokenDTO: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Int
    let athleteId: Int?
    let athleteName: String?
}
