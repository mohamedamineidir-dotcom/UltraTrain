import Foundation
import os

@Observable
@MainActor
final class EmailVerificationViewModel {
    private let authService: any AuthServiceProtocol

    var code = ""
    var isLoading = false
    var error: String?
    var isVerified = false
    var resendCooldown = 0

    private var cooldownTask: Task<Void, Never>?

    init(authService: any AuthServiceProtocol) {
        self.authService = authService
    }

    func verify() async {
        guard !code.isEmpty else {
            error = "Please enter the verification code"
            return
        }

        guard code.count == 6 else {
            error = "Code must be 6 digits"
            return
        }

        isLoading = true
        error = nil

        do {
            try await authService.verifyEmail(code: code)
            isVerified = true
        } catch {
            self.error = error.localizedDescription
            Logger.network.error("Email verification failed: \(error)")
        }

        isLoading = false
    }

    func resendCode() async {
        guard resendCooldown == 0 else { return }

        isLoading = true
        error = nil

        do {
            try await authService.resendVerificationCode()
            startCooldown()
        } catch {
            self.error = error.localizedDescription
            Logger.network.error("Resend verification failed: \(error)")
        }

        isLoading = false
    }

    private func startCooldown() {
        resendCooldown = 60
        cooldownTask?.cancel()
        cooldownTask = Task {
            while resendCooldown > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                resendCooldown -= 1
            }
        }
    }
}
