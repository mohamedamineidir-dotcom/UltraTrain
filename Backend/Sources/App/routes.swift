import Vapor

func routes(_ app: Application) throws {
    let rateLimited = app.grouped("v1")
        .grouped(RateLimitMiddleware(maxRequests: 60, windowSeconds: 60))

    // Health check outside HMAC — Railway uses this for health probes
    rateLimited.get("health") { _ in
        ["status": "ok"]
    }

    let api: RoutesBuilder
    if let hmacSecret = Environment.get("HMAC_SECRET") {
        api = rateLimited.grouped(HMACVerificationMiddleware(secret: hmacSecret))
    } else if app.environment == .production {
        fatalError("HMAC_SECRET must be set in production")
    } else {
        app.logger.warning("HMAC_SECRET not set — request signing verification disabled")
        api = rateLimited
    }

    // Public pages (outside /v1, own rate limit)
    let publicLimited = app.grouped(RateLimitMiddleware(maxRequests: 30, windowSeconds: 60))
    try publicLimited.register(collection: PrivacyController())

    try api.register(collection: AuthController())
    try api.register(collection: AthleteController())
    try api.register(collection: RunController())
    try api.register(collection: DeviceTokenController())
    try api.register(collection: TrainingPlanController())
    try api.register(collection: RaceController())
    try api.register(collection: SocialProfileController())
    try api.register(collection: FriendController())
    try api.register(collection: ActivityFeedController())
    try api.register(collection: SharedRunController())
    try api.register(collection: GroupChallengeController())

    try api.register(collection: NutritionController())
    try api.register(collection: FitnessController())
    try api.register(collection: FinishEstimateController())
    try api.register(collection: ChallengeController())

    // Crash reports — no auth required, aggressively rate-limited
    try api.register(collection: CrashReportController())

    // Analytics — no auth required
    try api.register(collection: AnalyticsController())
}
