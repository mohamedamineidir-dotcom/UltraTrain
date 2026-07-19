import Vapor

struct RegisterRequest: Content, Validatable {
    let email: String
    let password: String
    var firstName: String?
    var referralCode: String?

    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...128))
    }
}

struct SocialAuthResponse: Content {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    let isNewUser: Bool
    /// The name on file for this account, persisted from whichever
    /// authorization first supplied it. Lets the client restore a
    /// confirmed name after a reinstall or repeat Sign in with Apple,
    /// where the OS credential itself no longer includes it.
    let firstName: String?
    let lastName: String?

    init(
        accessToken: String,
        refreshToken: String,
        expiresIn: Int = 900,
        isNewUser: Bool,
        firstName: String? = nil,
        lastName: String? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.tokenType = "Bearer"
        self.isNewUser = isNewUser
        self.firstName = firstName
        self.lastName = lastName
    }
}

struct AppleSignInRequest: Content {
    let identityToken: String
    let firstName: String?
    let lastName: String?
}

struct GoogleSignInRequest: Content {
    let idToken: String
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

struct VerifyEmailRequest: Content, Validatable {
    let code: String

    static func validations(_ validations: inout Validations) {
        validations.add("code", as: String.self, is: .count(6...6))
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
