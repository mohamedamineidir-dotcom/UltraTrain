import Foundation
import os

@Observable
@MainActor
final class ForgotPasswordViewModel {
    private let authService: any AuthServiceProtocol

    var email = ""
    var code = ""
    var newPassword = ""
    var isLoading = false
    var error: String?
    var step: Step = .enterEmail
    var isResetComplete = false

    enum Step {
        case enterEmail
        case enterCode
    }

    init(authService: any AuthServiceProtocol) {
        self.authService = authService
    }

    func requestReset() async {
        guard !email.isEmpty else {
            error = "Please enter your email"
            return
        }

        isLoading = true
        error = nil

        do {
            try await authService.requestPasswordReset(email: email)
            step = .enterCode
        } catch {
            self.error = error.localizedDescription
            Logger.network.error("Password reset request failed: \(error)")
        }

        isLoading = false
    }

    func resetPassword() async {
        guard !code.isEmpty, !newPassword.isEmpty else {
            error = "Please fill in all fields"
            return
        }

        guard newPassword.count >= 8 else {
            error = "Password must be at least 8 characters"
            return
        }

        isLoading = true
        error = nil

        do {
            try await authService.resetPassword(
                email: email,
                code: code,
                newPassword: newPassword
            )
            isResetComplete = true
            code = ""
            newPassword = ""
        } catch {
            self.error = error.localizedDescription
            Logger.network.error("Password reset failed: \(error)")
        }

        isLoading = false
    }
}
