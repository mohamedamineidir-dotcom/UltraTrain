import Vapor
import Fluent

// MARK: - Email Verification (Verify, Resend)

extension AuthController {

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
}
