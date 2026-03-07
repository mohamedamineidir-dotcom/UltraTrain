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
    var firstName: String?
    var referralCode: String?
}

struct AppleSignInRequestDTO: Encodable, Sendable {
    let identityToken: String
    var firstName: String?
    var lastName: String?
}

struct GoogleSignInRequestDTO: Encodable, Sendable {
    let idToken: String
}

struct SocialAuthResponseDTO: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    let isNewUser: Bool
}

struct ReferralCodeResponseDTO: Decodable, Sendable {
    let referralCode: String
    let referralCount: Int
}

struct ApplyReferralRequestDTO: Encodable, Sendable {
    let code: String
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

struct VerifyEmailRequestDTO: Encodable, Sendable {
    let code: String
}

struct MessageResponseDTO: Decodable, Sendable {
    let message: String
}
