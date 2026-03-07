import Foundation
import os

@Observable
@MainActor
final class SignInViewModel {
    let authService: any AuthServiceProtocol

    var email = ""
    var password = ""
    var isLoading = false
    var error: String?
    var isAuthenticated = false

    var isAppleLoading = false
    var isGoogleLoading = false
    var isStravaLoading = false

    init(authService: any AuthServiceProtocol) {
        self.authService = authService
    }

    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            error = "Please enter email and password"
            return
        }

        isLoading = true
        error = nil

        do {
            try await authService.login(email: email, password: password)
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
            Logger.network.error("SignIn: login failed: \(error)")
        }

        isLoading = false
    }

    func handleAppleSignIn(identityToken: String, firstName: String?, lastName: String?) async {
        isAppleLoading = true
        error = nil

        do {
            _ = try await authService.signInWithApple(
                identityToken: identityToken,
                firstName: firstName, lastName: lastName
            )
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
            Logger.network.error("SignIn: Apple sign-in failed: \(error)")
        }

        isAppleLoading = false
    }

    func handleGoogleSignIn(idToken: String) async {
        isGoogleLoading = true
        error = nil

        do {
            _ = try await authService.signInWithGoogle(idToken: idToken)
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
            Logger.network.error("SignIn: Google sign-in failed: \(error)")
        }

        isGoogleLoading = false
    }
}
