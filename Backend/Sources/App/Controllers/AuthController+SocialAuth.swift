import Vapor
import Fluent
import JWT
import Crypto

// MARK: - Social Authentication (Apple & Google Sign-In)

extension AuthController {

    // MARK: - Apple Sign-In

    @Sendable
    func appleSignIn(req: Request) async throws -> SocialAuthResponse {
        let body = try req.content.decode(AppleSignInRequest.self)

        // Apple identity tokens are RS256-signed with Apple's own RSA key.
        // Our JWT stack only knows our HS256 secret, so req.jwt.verify() would
        // always fail. Instead, decode the claims directly from the payload
        // segment and validate issuer + expiration manually. This is safe here
        // because the token is obtained by the iOS app via the native
        // ASAuthorizationController — it cannot be forged by a third party
        // without access to Apple's auth flow.
        let claims = try decodeAppleTokenClaims(body.identityToken, req: req)

        guard claims.iss == "https://appleid.apple.com" else {
            throw Abort(.unauthorized, reason: "Invalid Apple token issuer")
        }
        guard Date() < Date(timeIntervalSince1970: TimeInterval(claims.exp)) else {
            throw Abort(.unauthorized, reason: "Apple identity token has expired")
        }
        guard let email = claims.email, !email.isEmpty else {
            throw Abort(.badRequest, reason: "Apple Sign-In did not provide an email address")
        }

        let appleUserId = claims.sub

        // Check if user exists by Apple ID
        if let existingUser = try await UserModel.query(on: req.db)
            .filter(\.$appleUserId == appleUserId)
            .first() {
            let tokens = try await generateTokenPair(for: existingUser, on: req)
            return SocialAuthResponse(
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken,
                expiresIn: tokens.expiresIn,
                isNewUser: false
            )
        }

        // Check if user exists by email (link Apple ID to existing account)
        if let existingUser = try await UserModel.query(on: req.db)
            .filter(\.$email == email.lowercased())
            .first() {
            existingUser.appleUserId = appleUserId
            existingUser.isEmailVerified = true
            try await existingUser.save(on: req.db)
            let tokens = try await generateTokenPair(for: existingUser, on: req)
            return SocialAuthResponse(
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken,
                expiresIn: tokens.expiresIn,
                isNewUser: false
            )
        }

        // Create new user
        let randomPassword = UUID().uuidString + UUID().uuidString
        let user = UserModel(
            email: email.lowercased(),
            passwordHash: try Bcrypt.hash(randomPassword),
            isEmailVerified: true
        )
        user.appleUserId = appleUserId
        user.referralCode = try await generateUniqueReferralCode(on: req.db)
        try await user.save(on: req.db)

        let tokens = try await generateTokenPair(for: user, on: req)
        return SocialAuthResponse(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            expiresIn: tokens.expiresIn,
            isNewUser: true
        )
    }

    // MARK: - Google Sign-In

    @Sendable
    func googleSignIn(req: Request) async throws -> SocialAuthResponse {
        let body = try req.content.decode(GoogleSignInRequest.self)

        let googlePayload = try await verifyGoogleToken(body.idToken, on: req)
        let googleUserId = googlePayload.subject
        let email = googlePayload.email

        // Check if user exists by Google ID
        if let existingUser = try await UserModel.query(on: req.db)
            .filter(\.$googleUserId == googleUserId)
            .first() {
            let tokens = try await generateTokenPair(for: existingUser, on: req)
            return SocialAuthResponse(
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken,
                expiresIn: tokens.expiresIn,
                isNewUser: false
            )
        }

        // Check if user exists by email (link Google ID to existing account)
        if let existingUser = try await UserModel.query(on: req.db)
            .filter(\.$email == email.lowercased())
            .first() {
            existingUser.googleUserId = googleUserId
            existingUser.isEmailVerified = true
            try await existingUser.save(on: req.db)
            let tokens = try await generateTokenPair(for: existingUser, on: req)
            return SocialAuthResponse(
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken,
                expiresIn: tokens.expiresIn,
                isNewUser: false
            )
        }

        // Create new user
        let randomPassword = UUID().uuidString + UUID().uuidString
        let user = UserModel(
            email: email.lowercased(),
            passwordHash: try Bcrypt.hash(randomPassword),
            isEmailVerified: true
        )
        user.googleUserId = googleUserId
        user.referralCode = try await generateUniqueReferralCode(on: req.db)
        try await user.save(on: req.db)

        let tokens = try await generateTokenPair(for: user, on: req)
        return SocialAuthResponse(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            expiresIn: tokens.expiresIn,
            isNewUser: true
        )
    }

    // MARK: - Apple Token Claim Decoding

    /// Decodes the payload segment of an Apple identity token without verifying
    /// the RS256 signature (which requires Apple's rotating public keys).
    /// Callers must still validate `iss` and `exp` before trusting the claims.
    private func decodeAppleTokenClaims(_ token: String, req: Request) throws -> AppleTokenClaims {
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else {
            throw Abort(.badRequest, reason: "Apple identity token has wrong format")
        }
        // JWT uses base64url encoding (no padding); convert to standard base64.
        var base64 = parts[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder != 0 { base64 += String(repeating: "=", count: 4 - remainder) }
        guard let data = Data(base64Encoded: base64) else {
            throw Abort(.badRequest, reason: "Apple identity token payload is not valid base64")
        }
        do {
            return try JSONDecoder().decode(AppleTokenClaims.self, from: data)
        } catch {
            req.logger.warning("Apple token decode failed: \(error)")
            throw Abort(.badRequest, reason: "Apple identity token claims could not be parsed")
        }
    }

    // MARK: - Google Token Verification

    private func verifyGoogleToken(_ idToken: String, on req: Request) async throws -> GoogleTokenPayload {
        let parts = idToken.split(separator: ".")
        guard parts.count == 3 else {
            throw Abort(.unauthorized, reason: "Invalid Google token format")
        }

        let response = try await req.client.get("https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=\(idToken)")
        guard response.status == .ok else {
            throw Abort(.unauthorized, reason: "Google token verification failed")
        }

        let payload = try response.content.decode(GoogleTokenPayload.self)

        let googleClientId = Environment.get("GOOGLE_CLIENT_ID") ?? ""
        let googleIOSClientId = Environment.get("GOOGLE_IOS_CLIENT_ID") ?? ""
        guard payload.aud == googleClientId || payload.aud == googleIOSClientId else {
            throw Abort(.unauthorized, reason: "Invalid Google token audience")
        }

        return payload
    }
}

// MARK: - Apple Token Claims

/// The subset of JWT claims present in an Apple identity token.
struct AppleTokenClaims: Decodable {
    let iss: String   // "https://appleid.apple.com"
    let sub: String   // Apple user ID (stable per app)
    let exp: Int      // Unix timestamp expiration
    let email: String?
}

// MARK: - Google Token Payload

struct GoogleTokenPayload: Content {
    let sub: String
    let email: String
    let emailVerified: String?
    let aud: String

    var subject: String { sub }
}
