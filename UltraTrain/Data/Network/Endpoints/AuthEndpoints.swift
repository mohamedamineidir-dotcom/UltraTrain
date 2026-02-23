import Foundation

enum AuthEndpoints {
    static let registerPath = "/auth/register"
    static let loginPath = "/auth/login"
    static let refreshPath = "/auth/refresh"
    static let logoutPath = "/auth/logout"
    static let deleteAccountPath = "/auth/account"
    static let changePasswordPath = "/auth/change-password"
    static let forgotPasswordPath = "/auth/forgot-password"
    static let resetPasswordPath = "/auth/reset-password"
    static let verifyEmailPath = "/auth/verify-email"
    static let resendVerificationPath = "/auth/resend-verification"
}
