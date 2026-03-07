import Vapor
import Fluent
import JWT
import Crypto

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        let authRateLimited = auth.grouped(RateLimitMiddleware(maxRequests: 5, windowSeconds: 60))
        authRateLimited.post("register", use: register)
        authRateLimited.post("login", use: login)
        authRateLimited.post("refresh", use: refresh)
        authRateLimited.post("forgot-password", use: forgotPassword)
        authRateLimited.post("reset-password", use: resetPassword)
        authRateLimited.post("apple", use: appleSignIn)
        authRateLimited.post("google", use: googleSignIn)

        let protected = auth.grouped(UserAuthMiddleware())
        protected.post("logout", use: logout)
        protected.post("change-password", use: changePassword)
        protected.delete("account", use: deleteAccount)
        protected.post("verify-email", use: verifyEmail)
        protected.post("resend-verification", use: resendVerification)
    }

    // MARK: - Register

    @Sendable
    func register(req: Request) async throws -> TokenResponse {
        try RegisterRequest.validate(content: req)
        let body = try req.content.decode(RegisterRequest.self)

        let existingUser = try await UserModel.query(on: req.db)
            .filter(\.$email == body.email.lowercased())
            .first()

        guard existingUser == nil else {
            throw Abort(.conflict, reason: "Registration failed")
        }

        let passwordHash = try Bcrypt.hash(body.password)
        let user = UserModel(email: body.email.lowercased(), passwordHash: passwordHash)

        // Generate unique referral code
        user.referralCode = try await generateUniqueReferralCode(on: req.db)

        // Apply referral code if provided (silently ignore invalid codes)
        if let refCode = body.referralCode?.uppercased(), !refCode.isEmpty {
            if let referrer = try await UserModel.query(on: req.db)
                .filter(\.$referralCode == refCode)
                .first() {
                user.referredByUserId = referrer.id
            }
        }

        // Generate verification code
        let code = String(format: "%06d", Int.random(in: 0...999999))
        user.verificationCodeHash = hashResetCode(code)
        user.verificationCodeExpiresAt = Date().addingTimeInterval(600) // 10 minutes
        try await user.save(on: req.db)

        // Send verification email
        let emailService = EmailService(app: req.application)
        await emailService.sendVerificationCode(to: body.email.lowercased(), code: code)

        return try await generateTokenPair(for: user, on: req)
    }

    // MARK: - Login

    @Sendable
    func login(req: Request) async throws -> TokenResponse {
        try LoginRequest.validate(content: req)
        let body = try req.content.decode(LoginRequest.self)

        guard let user = try await UserModel.query(on: req.db)
            .filter(\.$email == body.email.lowercased())
            .first() else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }

        guard try Bcrypt.verify(body.password, created: user.passwordHash) else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }

        return try await generateTokenPair(for: user, on: req)
    }

    // MARK: - Refresh

    @Sendable
    func refresh(req: Request) async throws -> TokenResponse {
        let body = try req.content.decode(RefreshRequest.self)
        let incomingHash = hashRefreshToken(body.refreshToken)

        guard let user = try await UserModel.query(on: req.db)
            .filter(\.$refreshTokenHash == incomingHash)
            .first() else {
            throw Abort(.unauthorized, reason: "Invalid refresh token")
        }

        return try await generateTokenPair(for: user, on: req)
    }

    // MARK: - Logout

    @Sendable
    func logout(req: Request) async throws -> HTTPStatus {
        let userId = try req.userId

        guard let user = try await UserModel.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }

        user.refreshTokenHash = nil
        try await user.save(on: req.db)

        return .noContent
    }

    // MARK: - Delete Account

    @Sendable
    func deleteAccount(req: Request) async throws -> HTTPStatus {
        let userId = try req.userId

        guard let user = try await UserModel.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }

        // Cascade deletes handle via foreign key ON DELETE CASCADE, but delete explicitly for safety
        // Social data
        try await FeedLikeModel.query(on: req.db).filter(\.$user.$id == userId).delete()
        try await ActivityFeedItemModel.query(on: req.db).filter(\.$user.$id == userId).delete()
        try await SharedRunRecipientModel.query(on: req.db).filter(\.$recipient.$id == userId).delete()
        try await SharedRunModel.query(on: req.db).filter(\.$user.$id == userId).delete()
        try await ChallengeParticipantModel.query(on: req.db).filter(\.$user.$id == userId).delete()
        try await GroupChallengeModel.query(on: req.db).filter(\.$creator.$id == userId).delete()
        try await FriendConnectionModel.query(on: req.db)
            .group(.or) { group in
                group.filter(\.$requestor.$id == userId)
                group.filter(\.$recipient.$id == userId)
            }
            .delete()
        // Core data
        try await RunModel.query(on: req.db).filter(\.$user.$id == userId).delete()
        try await TrainingPlanModel.query(on: req.db).filter(\.$user.$id == userId).delete()
        try await RaceModel.query(on: req.db).filter(\.$user.$id == userId).delete()
        try await AthleteModel.query(on: req.db).filter(\.$user.$id == userId).delete()
        try await user.delete(on: req.db)

        req.logger.info("Account deleted for user \(userId)")
        return .noContent
    }

    // MARK: - Token Generation

    func generateTokenPair(for user: UserModel, on req: Request) async throws -> TokenResponse {
        guard let userId = user.id else {
            throw Abort(.internalServerError, reason: "User has no ID")
        }

        let expiresIn = 900 // 15 minutes
        let payload = UserPayload(
            subject: .init(value: userId.uuidString),
            expiration: .init(value: Date().addingTimeInterval(TimeInterval(expiresIn))),
            email: user.email
        )

        let accessToken = try req.jwt.sign(payload)
        let refreshToken = UUID().uuidString + UUID().uuidString
        let refreshHash = hashRefreshToken(refreshToken)

        user.refreshTokenHash = refreshHash
        try await user.save(on: req.db)

        return TokenResponse(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
    }

    // MARK: - Helpers

    func hashRefreshToken(_ token: String) -> String {
        let digest = SHA256.hash(data: Data(token.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func hashResetCode(_ code: String) -> String {
        let digest = SHA256.hash(data: Data(code.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func generateUniqueReferralCode(on db: Database) async throws -> String {
        for _ in 0..<10 {
            let code = UserModel.generateReferralCode()
            let exists = try await UserModel.query(on: db)
                .filter(\.$referralCode == code)
                .first()
            if exists == nil { return code }
        }
        return String(UserModel.generateReferralCode().prefix(4) + UUID().uuidString.prefix(4).uppercased())
    }
}
