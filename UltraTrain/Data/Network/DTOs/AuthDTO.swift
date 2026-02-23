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

struct ForgotPasswordRequestDTO: Encodable, Sendable {
    let email: String
}

struct ResetPasswordRequestDTO: Encodable, Sendable {
    let email: String
    let code: String
    let newPassword: String
}

struct ChangePasswordRequestDTO: Encodable, Sendable {
    let currentPassword: String
    let newPassword: String
}

struct MessageResponseDTO: Decodable, Sendable {
    let message: String
}
