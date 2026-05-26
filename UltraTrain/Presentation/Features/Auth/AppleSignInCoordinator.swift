import AuthenticationServices
import UIKit

struct AppleSignInCredential {
    let identityToken: String
    let firstName: String?
    let lastName: String?
}

final class AppleSignInCoordinator: NSObject,
                                    ASAuthorizationControllerDelegate,
                                    ASAuthorizationControllerPresentationContextProviding,
                                    @unchecked Sendable {
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

    /// Required by `ASAuthorizationControllerPresentationContextProviding`.
    /// Without this, iOS 17+ rejects `performRequests()` with
    /// `ASAuthorizationError.unknown` (error 1000) because it has no
    /// window to attach the system Sign-in-with-Apple sheet to. Returns
    /// the current key window from the active foreground scene.
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let activeWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .windows.first(where: { $0.isKeyWindow })
        return activeWindow ?? ASPresentationAnchor()
    }

    enum AuthError: LocalizedError {
        case missingToken

        var errorDescription: String? {
            "Apple Sign-In failed to provide an identity token."
        }
    }
}
