import Foundation
import os

@Observable
@MainActor
final class LoginViewModel {
    private let authService: any AuthServiceProtocol

    var email = ""
    var password = ""
    var isRegistering = false
    var isLoading = false
    var error: String?
    var isAuthenticated = false
    var didRegister = false

    init(authService: any AuthServiceProtocol) {
        self.authService = authService
        isAuthenticated = authService.isAuthenticated()
    }

    func submit() async {
        guard !email.isEmpty, !password.isEmpty else {
            error = "Please enter email and password"
            return
        }

        isLoading = true
        error = nil

        do {
            if isRegistering {
                try await authService.register(email: email, password: password)
                didRegister = true
            } else {
                try await authService.login(email: email, password: password)
            }
            isAuthenticated = true
            password = ""
        } catch {
            self.error = error.localizedDescription
            Logger.network.error("Auth failed: \(error)")
        }

        isLoading = false
    }

    func logout() async {
        do {
            try await authService.logout()
            isAuthenticated = false
            email = ""
            password = ""
        } catch {
            Logger.network.error("Logout failed: \(error)")
        }
    }
}
