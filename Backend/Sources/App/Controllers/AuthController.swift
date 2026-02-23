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

        let protected = auth.grouped(UserAuthMiddleware())
        protected.post("logout", use: logout)
        protected.delete("account", use: deleteAccount)
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
        try await user.save(on: req.db)

        return try generateTokenPair(for: user, on: req)
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

        return try generateTokenPair(for: user, on: req)
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

        return try generateTokenPair(for: user, on: req)
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

        // Cascade deletes handle runs, athlete, training plans, races
        // via foreign key ON DELETE CASCADE, but delete explicitly for safety
        try await RunModel.query(on: req.db).filter(\.$user.$id == userId).delete()
        try await TrainingPlanModel.query(on: req.db).filter(\.$user.$id == userId).delete()
        try await RaceModel.query(on: req.db).filter(\.$user.$id == userId).delete()
        try await AthleteModel.query(on: req.db).filter(\.$user.$id == userId).delete()
        try await user.delete(on: req.db)

        req.logger.info("Account deleted for user \(userId)")
        return .noContent
    }

    // MARK: - Token Generation

    private func generateTokenPair(for user: UserModel, on req: Request) throws -> TokenResponse {
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
}
