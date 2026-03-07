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

        // Decode the Apple identity token (JWT) to extract the subject (user ID) and email
        let appleToken = try req.jwt.verify(body.identityToken, as: AppleIdentityToken.self)
        let appleUserId = appleToken.subject.value

        guard let email = appleToken.email else {
            throw Abort(.badRequest, reason: "Apple Sign-In did not provide an email")
        }

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
            existingUser.isEmailVerified = true // Apple verifies emails
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
            isEmailVerified: true // Apple verifies emails
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

        // Verify Google ID token by fetching Google's public keys
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

    // MARK: - Google Token Verification

    private func verifyGoogleToken(_ idToken: String, on req: Request) async throws -> GoogleTokenPayload {
        // Decode the JWT without verification first to get the header
        let parts = idToken.split(separator: ".")
        guard parts.count == 3 else {
            throw Abort(.unauthorized, reason: "Invalid Google token format")
        }

        // Fetch Google's public keys
        let response = try await req.client.get("https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=\(idToken)")
        guard response.status == .ok else {
            throw Abort(.unauthorized, reason: "Google token verification failed")
        }

        let payload = try response.content.decode(GoogleTokenPayload.self)

        // Verify the audience matches our client ID
        let googleClientId = Environment.get("GOOGLE_CLIENT_ID") ?? ""
        let googleIOSClientId = Environment.get("GOOGLE_IOS_CLIENT_ID") ?? ""
        guard payload.aud == googleClientId || payload.aud == googleIOSClientId else {
            throw Abort(.unauthorized, reason: "Invalid Google token audience")
        }

        return payload
    }
}

// MARK: - Apple Identity Token

struct AppleIdentityToken: JWTPayload {
    let subject: SubjectClaim
    let expiration: ExpirationClaim
    let issuer: IssuerClaim
    let audience: AudienceClaim
    let email: String?
    let emailVerified: String?

    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case issuer = "iss"
        case audience = "aud"
        case email
        case emailVerified = "email_verified"
    }

    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
        guard issuer.value == "https://appleid.apple.com" else {
            throw JWTError.claimVerificationFailure(name: "iss", reason: "Invalid issuer")
        }
    }
}

// MARK: - Google Token Payload

struct GoogleTokenPayload: Content {
    let sub: String
    let email: String
    let emailVerified: String?
    let aud: String

    var subject: String { sub }
}
