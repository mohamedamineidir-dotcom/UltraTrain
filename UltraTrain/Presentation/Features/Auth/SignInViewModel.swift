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

    // Result, mirrors SignUpViewModel — the name on file for the account,
    // used to restore onboarding's read-only name confirmation even when
    // this particular sign-in didn't come with a fresh Apple/Google credential.
    var authenticatedFirstName: String?
    var authenticatedLastName: String?

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
            let result = try await authService.signInWithApple(
                identityToken: identityToken,
                firstName: firstName, lastName: lastName
            )
            authenticatedFirstName = result.firstName ?? firstName
            authenticatedLastName = result.lastName ?? lastName
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
            let result = try await authService.signInWithGoogle(idToken: idToken)
            authenticatedFirstName = result.firstName
            authenticatedLastName = result.lastName
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
            Logger.network.error("SignIn: Google sign-in failed: \(error)")
        }

        isGoogleLoading = false
    }
}
