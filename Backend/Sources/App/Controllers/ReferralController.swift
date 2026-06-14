import Vapor
import Fluent

struct ReferralController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let referral = routes.grouped("referral")
            .grouped(UserAuthMiddleware())

        referral.get("me", use: getMyCode)

        let rateLimited = referral.grouped(RateLimitMiddleware(maxRequests: 3, windowSeconds: 60))
        rateLimited.post("apply", use: applyCode)
    }

    // MARK: - Get My Referral Code

    @Sendable
    func getMyCode(req: Request) async throws -> ReferralCodeResponse {
        let userId = try req.userId

        guard let user = try await UserModel.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }

        if user.referralCode == nil {
            // Generate one if missing (shouldn't happen for new users)
            user.referralCode = try await generateUniqueCode(on: req.db)
            try await user.save(on: req.db)
        }
        let count = try await referralCount(for: userId, on: req.db)
        return ReferralCodeResponse(
            referralCode: user.referralCode ?? "",
            referralCount: count,
            bonusAccessUntil: user.referralBonusUntil?.timeIntervalSince1970,
            rewardClaimed: user.referralRewardClaimedAt != nil,
            wasReferred: user.referredByUserId != nil
        )
    }

    // MARK: - Apply Referral Code

    @Sendable
    func applyCode(req: Request) async throws -> MessageResponse {
        try ApplyReferralRequest.validate(content: req)
        let body = try req.content.decode(ApplyReferralRequest.self)
        let userId = try req.userId

        guard let user = try await UserModel.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }

        // Already has a referrer
        guard user.referredByUserId == nil else {
            throw Abort(.conflict, reason: "Referral code already applied")
        }

        // Find the referrer by code
        guard let referrer = try await UserModel.query(on: req.db)
            .filter(\.$referralCode == body.code.uppercased())
            .first() else {
            throw Abort(.notFound, reason: "Invalid referral code")
        }

        // Can't refer yourself
        guard referrer.id != userId else {
            throw Abort(.badRequest, reason: "Cannot use your own referral code")
        }

        user.referredByUserId = referrer.id
        try await user.save(on: req.db)

        // Reward the REFERRER with a one-time +7 free-premium days. Once only
        // (non-cumulative) so a code can't be farmed for unlimited free access.
        // Banks onto any existing bonus window, floored at "now" so a lapsed
        // window doesn't shorten the grant.
        if referrer.referralRewardClaimedAt == nil {
            let now = Date()
            let base = max(referrer.referralBonusUntil ?? now, now)
            referrer.referralBonusUntil = base.addingTimeInterval(7 * 24 * 60 * 60)
            referrer.referralRewardClaimedAt = now
            try await referrer.save(on: req.db)
        }

        return MessageResponse(message: "Referral code applied successfully")
    }

    // MARK: - Helpers

    private func referralCount(for userId: UUID, on db: Database) async throws -> Int {
        try await UserModel.query(on: db)
            .filter(\.$referredByUserId == userId)
            .count()
    }

    private func generateUniqueCode(on db: Database) async throws -> String {
        for _ in 0..<10 {
            let code = UserModel.generateReferralCode()
            let exists = try await UserModel.query(on: db)
                .filter(\.$referralCode == code)
                .first()
            if exists == nil { return code }
        }
        // Extremely unlikely — fallback with UUID suffix
        return String(UserModel.generateReferralCode().prefix(4) + UUID().uuidString.prefix(4).uppercased())
    }
}
