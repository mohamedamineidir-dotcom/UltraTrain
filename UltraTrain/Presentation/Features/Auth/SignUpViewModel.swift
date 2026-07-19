import Foundation
import os

@Observable
@MainActor
final class SignUpViewModel {
    private let authService: any AuthServiceProtocol
    private let referralRepository: any ReferralRepository

    var firstName = ""
    var email = ""
    var password = ""
    var isLoading = false
    var error: String?
    var isAuthenticated = false

    // Social auth loading states
    var isAppleLoading = false
    var isGoogleLoading = false
    var isStravaLoading = false

    // Result
    var isNewUser = true
    var authenticatedFirstName: String?
    var authenticatedLastName: String?

    init(authService: any AuthServiceProtocol, referralRepository: any ReferralRepository) {
        self.authService = authService
        self.referralRepository = referralRepository
    }

    func createAccount() async {
        guard !email.isEmpty, !password.isEmpty else {
            error = "Please enter email and password"
            return
        }

        isLoading = true
        error = nil

        do {
            try await authService.register(
                email: email, password: password,
                firstName: nil,
                referralCode: nil
            )
            isNewUser = true
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
            Logger.network.error("SignUp: register failed: \(error)")
        }

        isLoading = false
    }

    func signInWithApple(identityToken: String, firstName: String?, lastName: String?) async {
        isAppleLoading = true
        error = nil

        do {
            let result = try await authService.signInWithApple(
                identityToken: identityToken,
                firstName: firstName, lastName: lastName
            )
            isNewUser = result.isNewUser
            // Prefer the name on file (persisted server-side) over the
            // credential's own value: on a repeat Sign in with Apple,
            // the OS credential no longer includes a name, but the
            // account already has one saved from the first authorization.
            authenticatedFirstName = result.firstName ?? firstName
            authenticatedLastName = result.lastName ?? lastName
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
            Logger.network.error("SignUp: Apple sign-in failed: \(error)")
        }

        isAppleLoading = false
    }

    func signInWithGoogle(idToken: String) async {
        isGoogleLoading = true
        error = nil

        do {
            let result = try await authService.signInWithGoogle(idToken: idToken)
            isNewUser = result.isNewUser
            authenticatedFirstName = result.firstName
            authenticatedLastName = result.lastName
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
            Logger.network.error("SignUp: Google sign-in failed: \(error)")
        }

        isGoogleLoading = false
    }
}
