import Foundation

enum AuthEndpoints {

    struct Register: APIEndpoint {
        typealias RequestBody = RegisterRequestDTO
        typealias ResponseBody = TokenResponseDTO
        let body: RegisterRequestDTO?
        var path: String { "/auth/register" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { false }

        init(email: String, password: String) {
            self.body = RegisterRequestDTO(email: email, password: password)
        }
    }

    struct Login: APIEndpoint {
        typealias RequestBody = LoginRequestDTO
        typealias ResponseBody = TokenResponseDTO
        let body: LoginRequestDTO?
        var path: String { "/auth/login" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { false }

        init(email: String, password: String) {
            self.body = LoginRequestDTO(email: email, password: password)
        }
    }

    struct Refresh: APIEndpoint {
        typealias RequestBody = RefreshRequestDTO
        typealias ResponseBody = TokenResponseDTO
        let body: RefreshRequestDTO?
        var path: String { "/auth/refresh" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { false }

        init(refreshToken: String) {
            self.body = RefreshRequestDTO(refreshToken: refreshToken)
        }
    }

    struct Logout: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = EmptyResponseBody
        var path: String { "/auth/logout" }
        var method: HTTPMethod { .post }
    }

    struct DeleteAccount: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = EmptyResponseBody
        var path: String { "/auth/account" }
        var method: HTTPMethod { .delete }
    }

    struct ChangePassword: APIEndpoint {
        typealias RequestBody = ChangePasswordRequestDTO
        typealias ResponseBody = MessageResponseDTO
        let body: ChangePasswordRequestDTO?
        var path: String { "/auth/change-password" }
        var method: HTTPMethod { .post }

        init(currentPassword: String, newPassword: String) {
            self.body = ChangePasswordRequestDTO(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
        }
    }

    struct ForgotPassword: APIEndpoint {
        typealias RequestBody = ForgotPasswordRequestDTO
        typealias ResponseBody = MessageResponseDTO
        let body: ForgotPasswordRequestDTO?
        var path: String { "/auth/forgot-password" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { false }

        init(email: String) {
            self.body = ForgotPasswordRequestDTO(email: email)
        }
    }

    struct ResetPassword: APIEndpoint {
        typealias RequestBody = ResetPasswordRequestDTO
        typealias ResponseBody = MessageResponseDTO
        let body: ResetPasswordRequestDTO?
        var path: String { "/auth/reset-password" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { false }

        init(email: String, code: String, newPassword: String) {
            self.body = ResetPasswordRequestDTO(
                email: email,
                code: code,
                newPassword: newPassword
            )
        }
    }

    struct VerifyEmail: APIEndpoint {
        typealias RequestBody = VerifyEmailRequestDTO
        typealias ResponseBody = MessageResponseDTO
        let body: VerifyEmailRequestDTO?
        var path: String { "/auth/verify-email" }
        var method: HTTPMethod { .post }

        init(code: String) {
            self.body = VerifyEmailRequestDTO(code: code)
        }
    }

    struct ResendVerification: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = MessageResponseDTO
        var path: String { "/auth/resend-verification" }
        var method: HTTPMethod { .post }
    }
}
