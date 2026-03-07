import AuthenticationServices

struct AppleSignInCredential {
    let identityToken: String
    let firstName: String?
    let lastName: String?
}

final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, @unchecked Sendable {
    /// Keep a strong reference so the delegate survives the async callback.
    static var current: AppleSignInCoordinator?

    private let completion: @Sendable (Result<AppleSignInCredential, Error>) -> Void

    init(completion: @escaping @Sendable (Result<AppleSignInCredential, Error>) -> Void) {
        self.completion = completion
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        defer { Self.current = nil }

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let tokenString = String(data: tokenData, encoding: .utf8) else {
            completion(.failure(AuthError.missingToken))
            return
        }

        let firstName = credential.fullName?.givenName
        let lastName = credential.fullName?.familyName

        completion(.success(AppleSignInCredential(
            identityToken: tokenString,
            firstName: firstName,
            lastName: lastName
        )))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        defer { Self.current = nil }
        // Don't report cancellation as an error
        if (error as? ASAuthorizationError)?.code == .canceled { return }
        completion(.failure(error))
    }

    enum AuthError: LocalizedError {
        case missingToken

        var errorDescription: String? {
            "Apple Sign-In failed to provide an identity token."
        }
    }
}
