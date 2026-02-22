import Foundation

struct TokenResponseDTO: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
}

struct RegisterRequestDTO: Encodable, Sendable {
    let email: String
    let password: String
}

struct LoginRequestDTO: Encodable, Sendable {
    let email: String
    let password: String
}

struct RefreshRequestDTO: Encodable, Sendable {
    let refreshToken: String
}
