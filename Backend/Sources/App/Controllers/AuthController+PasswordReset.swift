import Vapor
import Fluent
import Crypto

// MARK: - Password Management (Change, Forgot, Reset)

extension AuthController {

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
}
