import Vapor
import Fluent
import JWT

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("register", use: register)
        auth.post("login", use: login)
        auth.post("refresh", use: refresh)

        let protected = auth.grouped(UserAuthMiddleware())
        protected.post("logout", use: logout)
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
            throw Abort(.conflict, reason: "An account with this email already exists")
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
            throw Abort(.unauthorized, reason: "Invalid email or password")
        }

        guard try Bcrypt.verify(body.password, created: user.passwordHash) else {
            throw Abort(.unauthorized, reason: "Invalid email or password")
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
        let data = Data(token.utf8)
        return data.sha256.hexEncodedString()
    }
}

private extension Data {
    var sha256: Data {
        var hash = [UInt8](repeating: 0, count: 32)
        let bytes = Array(self)
        var h: [UInt32] = [
            0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
            0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
        ]
        let k: [UInt32] = [
            0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
            0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
            0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
            0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
            0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
            0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
            0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
            0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
            0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
            0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
            0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
            0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
            0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
            0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
            0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
            0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
        ]

        func rr(_ v: UInt32, _ n: UInt32) -> UInt32 { (v >> n) | (v << (32 - n)) }

        // Pad
        var msg = bytes
        msg.append(0x80)
        while msg.count % 64 != 56 { msg.append(0) }
        let bitLen = UInt64(bytes.count) * 8
        for i in (0..<8).reversed() { msg.append(UInt8((bitLen >> (i * 8)) & 0xFF)) }

        // Process blocks
        for blockStart in stride(from: 0, to: msg.count, by: 64) {
            let block = Array(msg[blockStart..<blockStart + 64])
            var w = [UInt32](repeating: 0, count: 64)
            for i in 0..<16 {
                w[i] = UInt32(block[i * 4]) << 24 | UInt32(block[i * 4 + 1]) << 16
                    | UInt32(block[i * 4 + 2]) << 8 | UInt32(block[i * 4 + 3])
            }
            for i in 16..<64 {
                let s0 = rr(w[i-15], 7) ^ rr(w[i-15], 18) ^ (w[i-15] >> 3)
                let s1 = rr(w[i-2], 17) ^ rr(w[i-2], 19) ^ (w[i-2] >> 10)
                w[i] = w[i-16] &+ s0 &+ w[i-7] &+ s1
            }
            var a = h[0], b = h[1], c = h[2], d = h[3]
            var e = h[4], f = h[5], g = h[6], hh = h[7]
            for i in 0..<64 {
                let s1 = rr(e, 6) ^ rr(e, 11) ^ rr(e, 25)
                let ch = (e & f) ^ (~e & g)
                let t1 = hh &+ s1 &+ ch &+ k[i] &+ w[i]
                let s0 = rr(a, 2) ^ rr(a, 13) ^ rr(a, 22)
                let maj = (a & b) ^ (a & c) ^ (b & c)
                let t2 = s0 &+ maj
                hh = g; g = f; f = e; e = d &+ t1
                d = c; c = b; b = a; a = t1 &+ t2
            }
            h[0] &+= a; h[1] &+= b; h[2] &+= c; h[3] &+= d
            h[4] &+= e; h[5] &+= f; h[6] &+= g; h[7] &+= hh
        }

        for (i, val) in h.enumerated() {
            hash[i * 4] = UInt8((val >> 24) & 0xFF)
            hash[i * 4 + 1] = UInt8((val >> 16) & 0xFF)
            hash[i * 4 + 2] = UInt8((val >> 8) & 0xFF)
            hash[i * 4 + 3] = UInt8(val & 0xFF)
        }
        return Data(hash)
    }

    func hexEncodedString() -> String {
        map { String(format: "%02x", $0) }.joined()
    }
}
