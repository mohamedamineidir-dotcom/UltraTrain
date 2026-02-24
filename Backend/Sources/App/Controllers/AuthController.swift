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

    // MARK: - Change Password

    @Sendable
    func changePassword(req: Request) async throws -> MessageResponse {
        try ChangePasswordRequest.validate(content: req)
        let body = try req.content.decode(ChangePasswordRequest.self)
        let userId = try req.userId

        guard let user = try await UserModel.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }

        guard try Bcrypt.verify(body.currentPassword, created: user.passwordHash) else {
            throw Abort(.unauthorized, reason: "Current password is incorrect")
        }

        user.passwordHash = try Bcrypt.hash(body.newPassword)
        user.refreshTokenHash = nil
        try await user.save(on: req.db)

        req.logger.info("Password changed for user \(userId)")
        return MessageResponse(message: "Password changed successfully")
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

    // MARK: - Forgot Password

    @Sendable
    func forgotPassword(req: Request) async throws -> MessageResponse {
        try ForgotPasswordRequest.validate(content: req)
        let body = try req.content.decode(ForgotPasswordRequest.self)

        // Always return success to prevent email enumeration
        guard let user = try await UserModel.query(on: req.db)
            .filter(\.$email == body.email.lowercased())
            .first() else {
            return MessageResponse(message: "If an account exists, a reset code has been sent.")
        }

        // Generate 6-digit code
        let code = String(format: "%06d", Int.random(in: 0...999999))
        let codeHash = hashResetCode(code)

        user.resetCodeHash = codeHash
        user.resetCodeExpiresAt = Date().addingTimeInterval(600) // 10 minutes
        try await user.save(on: req.db)

        let emailService = EmailService(app: req.application)
        await emailService.sendPasswordResetCode(to: body.email.lowercased(), code: code)

        return MessageResponse(message: "If an account exists, a reset code has been sent.")
    }

    // MARK: - Reset Password

    @Sendable
    func resetPassword(req: Request) async throws -> MessageResponse {
        try ResetPasswordRequest.validate(content: req)
        let body = try req.content.decode(ResetPasswordRequest.self)

        guard let user = try await UserModel.query(on: req.db)
            .filter(\.$email == body.email.lowercased())
            .first() else {
            throw Abort(.badRequest, reason: "Invalid reset code")
        }

        guard let storedHash = user.resetCodeHash,
              let expiresAt = user.resetCodeExpiresAt else {
            throw Abort(.badRequest, reason: "Invalid reset code")
        }

        guard Date() < expiresAt else {
            user.resetCodeHash = nil
            user.resetCodeExpiresAt = nil
            try await user.save(on: req.db)
            throw Abort(.badRequest, reason: "Reset code expired")
        }

        let incomingHash = hashResetCode(body.code)
        guard incomingHash == storedHash else {
            throw Abort(.badRequest, reason: "Invalid reset code")
        }

        // Update password and clear reset code
        user.passwordHash = try Bcrypt.hash(body.newPassword)
        user.resetCodeHash = nil
        user.resetCodeExpiresAt = nil
        user.refreshTokenHash = nil // Invalidate existing sessions
        try await user.save(on: req.db)

        req.logger.info("Password reset for \(body.email)")
        return MessageResponse(message: "Password reset successfully")
    }

    // MARK: - Verify Email

    @Sendable
    func verifyEmail(req: Request) async throws -> MessageResponse {
        try VerifyEmailRequest.validate(content: req)
        let body = try req.content.decode(VerifyEmailRequest.self)
        let userId = try req.userId

        guard let user = try await UserModel.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }

        if user.isEmailVerified {
            return MessageResponse(message: "Email already verified")
        }

        guard let storedHash = user.verificationCodeHash,
              let expiresAt = user.verificationCodeExpiresAt else {
            throw Abort(.badRequest, reason: "No verification code pending. Request a new one.")
        }

        guard Date() < expiresAt else {
            user.verificationCodeHash = nil
            user.verificationCodeExpiresAt = nil
            try await user.save(on: req.db)
            throw Abort(.badRequest, reason: "Verification code expired. Request a new one.")
        }

        let incomingHash = hashResetCode(body.code)
        guard incomingHash == storedHash else {
            throw Abort(.badRequest, reason: "Invalid verification code")
        }

        user.isEmailVerified = true
        user.verificationCodeHash = nil
        user.verificationCodeExpiresAt = nil
        try await user.save(on: req.db)

        req.logger.info("Email verified for user \(userId)")
        return MessageResponse(message: "Email verified successfully")
    }

    // MARK: - Resend Verification

    @Sendable
    func resendVerification(req: Request) async throws -> MessageResponse {
        let userId = try req.userId

        guard let user = try await UserModel.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }

        if user.isEmailVerified {
            return MessageResponse(message: "Email already verified")
        }

        let code = String(format: "%06d", Int.random(in: 0...999999))
        user.verificationCodeHash = hashResetCode(code)
        user.verificationCodeExpiresAt = Date().addingTimeInterval(600) // 10 minutes
        try await user.save(on: req.db)

        let emailService = EmailService(app: req.application)
        await emailService.sendVerificationCode(to: user.email, code: code)

        return MessageResponse(message: "Verification code sent")
    }

    // MARK: - Token Generation

    private func generateTokenPair(for user: UserModel, on req: Request) async throws -> TokenResponse {
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

    private func hashRefreshToken(_ token: String) -> String {
        let digest = SHA256.hash(data: Data(token.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func hashResetCode(_ code: String) -> String {
        let digest = SHA256.hash(data: Data(code.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
