import GoogleSignIn
import UIKit
import os

enum GoogleSignInCoordinator {
    @MainActor
    static func signIn() async throws -> String {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw GoogleSignInError.noPresenter
        }

        let clientId = AppConfiguration.Google.clientId
        guard !clientId.isEmpty else {
            Logger.app.error("GOOGLE_CLIENT_ID not configured in Secrets.xcconfig")
            throw GoogleSignInError.notConfigured
        }

        let config = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

        guard let idToken = result.user.idToken?.tokenString else {
            throw GoogleSignInError.missingIdToken
        }

        return idToken
    }
}

enum GoogleSignInError: Error, LocalizedError {
    case noPresenter
    case notConfigured
    case missingIdToken

    var errorDescription: String? {
        switch self {
        case .noPresenter: "Unable to present Google Sign-In"
        case .notConfigured: "Google Sign-In is not configured"
        case .missingIdToken: "Google Sign-In did not return an ID token"
        }
    }
}
