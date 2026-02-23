import Vapor

struct RegisterRequest: Content, Validatable {
    let email: String
    let password: String

    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...128))
    }
}

struct LoginRequest: Content, Validatable {
    let email: String
    let password: String

    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: !.empty)
    }
}

struct RefreshRequest: Content {
    let refreshToken: String
}

struct ForgotPasswordRequest: Content, Validatable {
    let email: String

    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
    }
}

struct ResetPasswordRequest: Content, Validatable {
    let email: String
    let code: String
    let newPassword: String

    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("code", as: String.self, is: .count(6...6))
        validations.add("newPassword", as: String.self, is: .count(8...128))
    }
}

struct ChangePasswordRequest: Content, Validatable {
    let currentPassword: String
    let newPassword: String

    static func validations(_ validations: inout Validations) {
        validations.add("currentPassword", as: String.self, is: !.empty)
        validations.add("newPassword", as: String.self, is: .count(8...128))
    }
}

struct MessageResponse: Content {
    let message: String
}

struct TokenResponse: Content {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String

    init(accessToken: String, refreshToken: String, expiresIn: Int = 900) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.tokenType = "Bearer"
    }
}
