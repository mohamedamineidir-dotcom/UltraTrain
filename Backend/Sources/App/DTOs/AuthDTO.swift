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
