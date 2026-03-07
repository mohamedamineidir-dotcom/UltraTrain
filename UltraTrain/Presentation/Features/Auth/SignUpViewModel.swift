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

    init(authService: any AuthServiceProtocol, referralRepository: any ReferralRepository) {
        self.authService = authService
        self.referralRepository = referralRepository
    }

    func createAccount() async {
        guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Please enter your first name"
            return
        }
        guard !email.isEmpty, !password.isEmpty else {
            error = "Please enter email and password"
            return
        }

        isLoading = true
        error = nil

        do {
            try await authService.register(
                email: email, password: password,
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                referralCode: nil
            )
            authenticatedFirstName = firstName.trimmingCharacters(in: .whitespaces)
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
            let newUser = try await authService.signInWithApple(
                identityToken: identityToken,
                firstName: firstName, lastName: lastName
            )
            isNewUser = newUser
            authenticatedFirstName = firstName
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
            let newUser = try await authService.signInWithGoogle(idToken: idToken)
            isNewUser = newUser
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
            Logger.network.error("SignUp: Google sign-in failed: \(error)")
        }

        isGoogleLoading = false
    }
}
