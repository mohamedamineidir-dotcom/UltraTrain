@testable import App
import XCTVapor
import Fluent
import Crypto

final class AuthControllerTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = try await createTestApp()
    }

    override func tearDown() async throws {
        app.shutdown()
        app = nil
    }

    // MARK: - Register

    func testRegister_validCredentials_returnsTokens() async throws {
        try await app.test(.POST, "v1/auth/register", beforeRequest: { req in
            try req.content.encode(RegisterRequest(email: "new@example.com", password: "password123"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let tokens = try res.content.decode(TokenResponse.self)
            XCTAssertFalse(tokens.accessToken.isEmpty)
            XCTAssertFalse(tokens.refreshToken.isEmpty)
            XCTAssertEqual(tokens.expiresIn, 900)
            XCTAssertEqual(tokens.tokenType, "Bearer")
        })
    }

    func testRegister_duplicateEmail_returnsConflict() async throws {
        try await app.registerUser(email: "dup@example.com", password: "password123")

        try await app.test(.POST, "v1/auth/register", beforeRequest: { req in
            try req.content.encode(RegisterRequest(email: "dup@example.com", password: "password123"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .conflict)
        })
    }

    func testRegister_emailIsCaseInsensitive() async throws {
        try await app.registerUser(email: "User@Example.com", password: "password123")

        try await app.test(.POST, "v1/auth/register", beforeRequest: { req in
            try req.content.encode(RegisterRequest(email: "user@example.com", password: "password123"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .conflict)
        })
    }

    func testRegister_invalidEmail_returnsBadRequest() async throws {
        try await app.test(.POST, "v1/auth/register", beforeRequest: { req in
            try req.content.encode(RegisterRequest(email: "not-an-email", password: "password123"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testRegister_shortPassword_returnsBadRequest() async throws {
        try await app.test(.POST, "v1/auth/register", beforeRequest: { req in
            try req.content.encode(RegisterRequest(email: "test@example.com", password: "short"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testRegister_setsVerificationCode() async throws {
        try await app.registerUser(email: "verify@example.com", password: "password123")

        let user = try await UserModel.query(on: app.db)
            .filter(\.$email == "verify@example.com")
            .first()

        XCTAssertNotNil(user)
        XCTAssertFalse(user!.isEmailVerified)
        XCTAssertNotNil(user!.verificationCodeHash)
        XCTAssertNotNil(user!.verificationCodeExpiresAt)
    }

    // MARK: - Login

    func testLogin_validCredentials_returnsTokens() async throws {
        try await app.registerUser(email: "login@example.com", password: "mypassword8")

        try await app.test(.POST, "v1/auth/login", beforeRequest: { req in
            try req.content.encode(LoginRequest(email: "login@example.com", password: "mypassword8"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let tokens = try res.content.decode(TokenResponse.self)
            XCTAssertFalse(tokens.accessToken.isEmpty)
            XCTAssertFalse(tokens.refreshToken.isEmpty)
        })
    }

    func testLogin_wrongPassword_returnsUnauthorized() async throws {
        try await app.registerUser(email: "wrong@example.com", password: "password123")

        try await app.test(.POST, "v1/auth/login", beforeRequest: { req in
            try req.content.encode(LoginRequest(email: "wrong@example.com", password: "wrongpassword"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testLogin_nonexistentUser_returnsUnauthorized() async throws {
        try await app.test(.POST, "v1/auth/login", beforeRequest: { req in
            try req.content.encode(LoginRequest(email: "nobody@example.com", password: "password123"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testLogin_emailIsCaseInsensitive() async throws {
        try await app.registerUser(email: "Case@Example.com", password: "password123")

        try await app.test(.POST, "v1/auth/login", beforeRequest: { req in
            try req.content.encode(LoginRequest(email: "case@example.com", password: "password123"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
    }

    // MARK: - Refresh Token

    func testRefresh_validToken_returnsNewTokens() async throws {
        let user = try await app.registerUser(email: "refresh@example.com", password: "password123")

        try await app.test(.POST, "v1/auth/refresh", beforeRequest: { req in
            try req.content.encode(RefreshRequest(refreshToken: user.refreshToken!))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let tokens = try res.content.decode(TokenResponse.self)
            XCTAssertFalse(tokens.accessToken.isEmpty)
            XCTAssertFalse(tokens.refreshToken.isEmpty)
        })
    }

    func testRefresh_invalidToken_returnsUnauthorized() async throws {
        try await app.test(.POST, "v1/auth/refresh", beforeRequest: { req in
            try req.content.encode(RefreshRequest(refreshToken: "invalid-token"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testRefresh_rotatesRefreshToken() async throws {
        let user = try await app.registerUser(email: "rotate@example.com", password: "password123")
        let originalRefresh = user.refreshToken!

        var newRefresh: String?
        try await app.test(.POST, "v1/auth/refresh", beforeRequest: { req in
            try req.content.encode(RefreshRequest(refreshToken: originalRefresh))
        }, afterResponse: { res in
            let tokens = try res.content.decode(TokenResponse.self)
            newRefresh = tokens.refreshToken
        })

        // Old refresh token should no longer work
        try await app.test(.POST, "v1/auth/refresh", beforeRequest: { req in
            try req.content.encode(RefreshRequest(refreshToken: originalRefresh))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })

        // New refresh token should work
        try await app.test(.POST, "v1/auth/refresh", beforeRequest: { req in
            try req.content.encode(RefreshRequest(refreshToken: newRefresh!))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
    }

    // MARK: - Logout

    func testLogout_authenticated_returnsNoContent() async throws {
        let user = try await app.registerUser(email: "logout@example.com", password: "password123")

        try await app.test(.POST, "v1/auth/logout", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })
    }

    func testLogout_invalidatesRefreshToken() async throws {
        let user = try await app.registerUser(email: "logoutinv@example.com", password: "password123")

        // Logout
        try await app.test(.POST, "v1/auth/logout", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })

        // Refresh token should no longer work
        try await app.test(.POST, "v1/auth/refresh", beforeRequest: { req in
            try req.content.encode(RefreshRequest(refreshToken: user.refreshToken!))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testLogout_noAuth_returnsUnauthorized() async throws {
        try await app.test(.POST, "v1/auth/logout", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - Change Password

    func testChangePassword_validRequest_succeeds() async throws {
        let user = try await app.registerUser(email: "changepw@example.com", password: "oldpassword1")

        try await app.test(.POST, "v1/auth/change-password", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(ChangePasswordRequest(currentPassword: "oldpassword1", newPassword: "newpassword1"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let msg = try res.content.decode(MessageResponse.self)
            XCTAssertEqual(msg.message, "Password changed successfully")
        })

        // Can login with new password
        try await app.test(.POST, "v1/auth/login", beforeRequest: { req in
            try req.content.encode(LoginRequest(email: "changepw@example.com", password: "newpassword1"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
    }

    func testChangePassword_wrongCurrentPassword_returnsUnauthorized() async throws {
        let user = try await app.registerUser(email: "wrongcur@example.com", password: "password123")

        try await app.test(.POST, "v1/auth/change-password", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(ChangePasswordRequest(currentPassword: "wrongpassword", newPassword: "newpassword1"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testChangePassword_invalidatesRefreshTokens() async throws {
        let user = try await app.registerUser(email: "cpwinv@example.com", password: "password123")

        try await app.test(.POST, "v1/auth/change-password", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(ChangePasswordRequest(currentPassword: "password123", newPassword: "newpassword1"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        // Old refresh token should not work
        try await app.test(.POST, "v1/auth/refresh", beforeRequest: { req in
            try req.content.encode(RefreshRequest(refreshToken: user.refreshToken!))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testChangePassword_noAuth_returnsUnauthorized() async throws {
        try await app.test(.POST, "v1/auth/change-password", beforeRequest: { req in
            try req.content.encode(ChangePasswordRequest(currentPassword: "pw", newPassword: "newpassword1"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - Delete Account

    func testDeleteAccount_authenticated_returnsNoContent() async throws {
        let user = try await app.registerUser(email: "delete@example.com", password: "password123")

        try await app.test(.DELETE, "v1/auth/account", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })

        // User should no longer exist
        let dbUser = try await UserModel.query(on: app.db)
            .filter(\.$email == "delete@example.com")
            .first()
        XCTAssertNil(dbUser)
    }

    func testDeleteAccount_cannotLoginAfterDeletion() async throws {
        let user = try await app.registerUser(email: "dellog@example.com", password: "password123")

        try await app.test(.DELETE, "v1/auth/account", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })

        try await app.test(.POST, "v1/auth/login", beforeRequest: { req in
            try req.content.encode(LoginRequest(email: "dellog@example.com", password: "password123"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testDeleteAccount_noAuth_returnsUnauthorized() async throws {
        try await app.test(.DELETE, "v1/auth/account", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - Forgot Password

    func testForgotPassword_existingUser_returnsSuccessMessage() async throws {
        try await app.registerUser(email: "forgot@example.com", password: "password123")

        try await app.test(.POST, "v1/auth/forgot-password", beforeRequest: { req in
            try req.content.encode(ForgotPasswordRequest(email: "forgot@example.com"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let msg = try res.content.decode(MessageResponse.self)
            XCTAssertTrue(msg.message.contains("reset code has been sent"))
        })

        // Verify reset code was stored
        let user = try await UserModel.query(on: app.db)
            .filter(\.$email == "forgot@example.com")
            .first()
        XCTAssertNotNil(user?.resetCodeHash)
        XCTAssertNotNil(user?.resetCodeExpiresAt)
    }

    func testForgotPassword_nonexistentUser_returnsSameMessage() async throws {
        try await app.test(.POST, "v1/auth/forgot-password", beforeRequest: { req in
            try req.content.encode(ForgotPasswordRequest(email: "nobody@example.com"))
        }, afterResponse: { res in
            // Should not reveal whether email exists
            XCTAssertEqual(res.status, .ok)
            let msg = try res.content.decode(MessageResponse.self)
            XCTAssertTrue(msg.message.contains("reset code has been sent"))
        })
    }

    func testForgotPassword_invalidEmail_returnsBadRequest() async throws {
        try await app.test(.POST, "v1/auth/forgot-password", beforeRequest: { req in
            try req.content.encode(ForgotPasswordRequest(email: "not-email"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    // MARK: - Reset Password

    func testResetPassword_validCode_succeeds() async throws {
        try await app.registerUser(email: "reset@example.com", password: "password123")

        // Manually set a known reset code
        let user = try await UserModel.query(on: app.db)
            .filter(\.$email == "reset@example.com")
            .first()!

        let code = "123456"
        let digest = SHA256.hash(data: Data(code.utf8))
        user.resetCodeHash = digest.map { String(format: "%02x", $0) }.joined()
        user.resetCodeExpiresAt = Date().addingTimeInterval(600)
        try await user.save(on: app.db)

        try await app.test(.POST, "v1/auth/reset-password", beforeRequest: { req in
            try req.content.encode(ResetPasswordRequest(email: "reset@example.com", code: "123456", newPassword: "newpassword1"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let msg = try res.content.decode(MessageResponse.self)
            XCTAssertEqual(msg.message, "Password reset successfully")
        })

        // Can login with new password
        try await app.test(.POST, "v1/auth/login", beforeRequest: { req in
            try req.content.encode(LoginRequest(email: "reset@example.com", password: "newpassword1"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
    }

    func testResetPassword_invalidCode_returnsBadRequest() async throws {
        try await app.registerUser(email: "badcode@example.com", password: "password123")

        let user = try await UserModel.query(on: app.db)
            .filter(\.$email == "badcode@example.com")
            .first()!

        let code = "123456"
        let digest = SHA256.hash(data: Data(code.utf8))
        user.resetCodeHash = digest.map { String(format: "%02x", $0) }.joined()
        user.resetCodeExpiresAt = Date().addingTimeInterval(600)
        try await user.save(on: app.db)

        try await app.test(.POST, "v1/auth/reset-password", beforeRequest: { req in
            try req.content.encode(ResetPasswordRequest(email: "badcode@example.com", code: "999999", newPassword: "newpassword1"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testResetPassword_expiredCode_returnsBadRequest() async throws {
        try await app.registerUser(email: "expired@example.com", password: "password123")

        let user = try await UserModel.query(on: app.db)
            .filter(\.$email == "expired@example.com")
            .first()!

        let code = "123456"
        let digest = SHA256.hash(data: Data(code.utf8))
        user.resetCodeHash = digest.map { String(format: "%02x", $0) }.joined()
        user.resetCodeExpiresAt = Date().addingTimeInterval(-60) // Already expired
        try await user.save(on: app.db)

        try await app.test(.POST, "v1/auth/reset-password", beforeRequest: { req in
            try req.content.encode(ResetPasswordRequest(email: "expired@example.com", code: "123456", newPassword: "newpassword1"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testResetPassword_invalidatesRefreshTokens() async throws {
        let registered = try await app.registerUser(email: "resetinv@example.com", password: "password123")

        let user = try await UserModel.query(on: app.db)
            .filter(\.$email == "resetinv@example.com")
            .first()!

        let code = "123456"
        let digest = SHA256.hash(data: Data(code.utf8))
        user.resetCodeHash = digest.map { String(format: "%02x", $0) }.joined()
        user.resetCodeExpiresAt = Date().addingTimeInterval(600)
        try await user.save(on: app.db)

        try await app.test(.POST, "v1/auth/reset-password", beforeRequest: { req in
            try req.content.encode(ResetPasswordRequest(email: "resetinv@example.com", code: "123456", newPassword: "newpassword1"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        // Old refresh token should not work
        try await app.test(.POST, "v1/auth/refresh", beforeRequest: { req in
            try req.content.encode(RefreshRequest(refreshToken: registered.refreshToken!))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - Verify Email

    func testVerifyEmail_validCode_succeeds() async throws {
        let user = try await app.registerUser(email: "verifyok@example.com", password: "password123")

        // Read the stored verification code hash, set a known one
        let dbUser = try await UserModel.query(on: app.db)
            .filter(\.$email == "verifyok@example.com")
            .first()!

        let code = "654321"
        let digest = SHA256.hash(data: Data(code.utf8))
        dbUser.verificationCodeHash = digest.map { String(format: "%02x", $0) }.joined()
        dbUser.verificationCodeExpiresAt = Date().addingTimeInterval(600)
        try await dbUser.save(on: app.db)

        try await app.test(.POST, "v1/auth/verify-email", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(VerifyEmailRequest(code: "654321"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let msg = try res.content.decode(MessageResponse.self)
            XCTAssertEqual(msg.message, "Email verified successfully")
        })

        // Verify DB state
        let updated = try await UserModel.query(on: app.db)
            .filter(\.$email == "verifyok@example.com")
            .first()!
        XCTAssertTrue(updated.isEmailVerified)
        XCTAssertNil(updated.verificationCodeHash)
        XCTAssertNil(updated.verificationCodeExpiresAt)
    }

    func testVerifyEmail_invalidCode_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "verifybad@example.com", password: "password123")

        try await app.test(.POST, "v1/auth/verify-email", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(VerifyEmailRequest(code: "000000"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testVerifyEmail_alreadyVerified_returnsSuccess() async throws {
        let user = try await app.registerUser(email: "alreadyv@example.com", password: "password123")

        let dbUser = try await UserModel.query(on: app.db)
            .filter(\.$email == "alreadyv@example.com")
            .first()!
        dbUser.isEmailVerified = true
        try await dbUser.save(on: app.db)

        try await app.test(.POST, "v1/auth/verify-email", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(VerifyEmailRequest(code: "123456"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let msg = try res.content.decode(MessageResponse.self)
            XCTAssertEqual(msg.message, "Email already verified")
        })
    }

    func testVerifyEmail_noAuth_returnsUnauthorized() async throws {
        try await app.test(.POST, "v1/auth/verify-email", beforeRequest: { req in
            try req.content.encode(VerifyEmailRequest(code: "123456"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - Resend Verification

    func testResendVerification_succeeds() async throws {
        let user = try await app.registerUser(email: "resend@example.com", password: "password123")

        // Clear the initial verification code
        let dbUser = try await UserModel.query(on: app.db)
            .filter(\.$email == "resend@example.com")
            .first()!
        dbUser.verificationCodeHash = nil
        dbUser.verificationCodeExpiresAt = nil
        try await dbUser.save(on: app.db)

        try await app.test(.POST, "v1/auth/resend-verification", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let msg = try res.content.decode(MessageResponse.self)
            XCTAssertEqual(msg.message, "Verification code sent")
        })

        // New code should be stored
        let updated = try await UserModel.query(on: app.db)
            .filter(\.$email == "resend@example.com")
            .first()!
        XCTAssertNotNil(updated.verificationCodeHash)
        XCTAssertNotNil(updated.verificationCodeExpiresAt)
    }

    func testResendVerification_alreadyVerified_returnsAlreadyMessage() async throws {
        let user = try await app.registerUser(email: "resendv@example.com", password: "password123")

        let dbUser = try await UserModel.query(on: app.db)
            .filter(\.$email == "resendv@example.com")
            .first()!
        dbUser.isEmailVerified = true
        try await dbUser.save(on: app.db)

        try await app.test(.POST, "v1/auth/resend-verification", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let msg = try res.content.decode(MessageResponse.self)
            XCTAssertEqual(msg.message, "Email already verified")
        })
    }

    func testResendVerification_noAuth_returnsUnauthorized() async throws {
        try await app.test(.POST, "v1/auth/resend-verification", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - Protected Routes Without Auth

    func testProtectedRoutes_withoutAuth_returnUnauthorized() async throws {
        try await app.test(.POST, "v1/auth/logout", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })

        try await app.test(.POST, "v1/auth/change-password", beforeRequest: { req in
            try req.content.encode(ChangePasswordRequest(currentPassword: "a", newPassword: "newpassword1"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })

        try await app.test(.DELETE, "v1/auth/account", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })

        try await app.test(.POST, "v1/auth/verify-email", beforeRequest: { req in
            try req.content.encode(VerifyEmailRequest(code: "123456"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })

        try await app.test(.POST, "v1/auth/resend-verification", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - Full Auth Flow

    func testFullAuthFlow_registerLoginRefreshLogout() async throws {
        // 1. Register
        var tokens: TokenResponse!
        try await app.test(.POST, "v1/auth/register", beforeRequest: { req in
            try req.content.encode(RegisterRequest(email: "flow@example.com", password: "password123"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            tokens = try res.content.decode(TokenResponse.self)
        })

        // 2. Access protected route with access token
        try await app.test(.POST, "v1/auth/logout", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: tokens.accessToken)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })

        // 3. Login again
        try await app.test(.POST, "v1/auth/login", beforeRequest: { req in
            try req.content.encode(LoginRequest(email: "flow@example.com", password: "password123"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            tokens = try res.content.decode(TokenResponse.self)
        })

        // 4. Refresh
        try await app.test(.POST, "v1/auth/refresh", beforeRequest: { req in
            try req.content.encode(RefreshRequest(refreshToken: tokens.refreshToken))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            tokens = try res.content.decode(TokenResponse.self)
        })

        // 5. Logout
        try await app.test(.POST, "v1/auth/logout", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: tokens.accessToken)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })

        // 6. Refresh should fail
        try await app.test(.POST, "v1/auth/refresh", beforeRequest: { req in
            try req.content.encode(RefreshRequest(refreshToken: tokens.refreshToken))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
}
