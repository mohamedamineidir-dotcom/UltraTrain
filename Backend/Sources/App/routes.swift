import Vapor

func routes(_ app: Application) throws {
    let api = app.grouped("v1")
        .grouped(RateLimitMiddleware(maxRequests: 60, windowSeconds: 60))

    api.get("health") { _ in
        ["status": "ok"]
    }

    // Public pages (outside /v1, no rate limit)
    try app.register(collection: PrivacyController())

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
}
