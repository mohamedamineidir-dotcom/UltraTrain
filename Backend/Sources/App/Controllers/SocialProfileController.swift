import Vapor
import Fluent

struct SocialProfileController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(UserAuthMiddleware())
        protected.get("social", "profile", use: getMyProfile)
        protected.put("social", "profile", use: updateMyProfile)
        protected.get("social", "profile", ":profileId", use: getProfile)
        protected.get("social", "search", use: searchProfiles)
    }

    @Sendable
    func getMyProfile(req: Request) async throws -> SocialProfileResponse {
        let userId = try req.userId

        guard let athlete = try await AthleteModel.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Athlete profile not found")
        }

        let stats = try await aggregateStats(userId: userId, on: req.db)
        let user = try await UserModel.find(userId, on: req.db)

        return SocialProfileResponse(
            from: athlete,
            userId: userId,
            totalDistanceKm: stats.distance,
            totalElevationGainM: stats.elevation,
            totalRuns: stats.count,
            joinedDate: user?.createdAt ?? Date()
        )
    }

    @Sendable
    func updateMyProfile(req: Request) async throws -> SocialProfileResponse {
        try SocialProfileUpdateRequest.validate(content: req)
        let body = try req.content.decode(SocialProfileUpdateRequest.self)
        let userId = try req.userId

        guard let athlete = try await AthleteModel.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Athlete profile not found")
        }

        athlete.displayName = body.displayName
        athlete.bio = body.bio
        athlete.isPublicProfile = body.isPublicProfile
        try await athlete.save(on: req.db)

        let stats = try await aggregateStats(userId: userId, on: req.db)
        let user = try await UserModel.find(userId, on: req.db)

        return SocialProfileResponse(
            from: athlete,
            userId: userId,
            totalDistanceKm: stats.distance,
            totalElevationGainM: stats.elevation,
            totalRuns: stats.count,
            joinedDate: user?.createdAt ?? Date()
        )
    }

    @Sendable
    func getProfile(req: Request) async throws -> SocialProfileResponse {
        guard let profileIdStr = req.parameters.get("profileId"),
              let profileId = UUID(uuidString: profileIdStr) else {
            throw Abort(.badRequest, reason: "Invalid profile ID")
        }

        guard let athlete = try await AthleteModel.query(on: req.db)
            .filter(\.$user.$id == profileId)
            .first() else {
            throw Abort(.notFound, reason: "Profile not found")
        }

        // Only show public profiles (or the user's own)
        let currentUserId = try req.userId
        if !athlete.isPublicProfile && profileId != currentUserId {
            throw Abort(.notFound, reason: "Profile not found")
        }

        let stats = try await aggregateStats(userId: profileId, on: req.db)
        let user = try await UserModel.find(profileId, on: req.db)

        return SocialProfileResponse(
            from: athlete,
            userId: profileId,
            totalDistanceKm: stats.distance,
            totalElevationGainM: stats.elevation,
            totalRuns: stats.count,
            joinedDate: user?.createdAt ?? Date()
        )
    }

    @Sendable
    func searchProfiles(req: Request) async throws -> [SocialProfileResponse] {
        guard let query = req.query[String.self, at: "q"],
              !query.isEmpty else {
            throw Abort(.badRequest, reason: "Search query 'q' is required")
        }

        let currentUserId = try req.userId

        // Search athletes by display_name, first_name, or last_name (case-insensitive)
        let athletes = try await AthleteModel.query(on: req.db)
            .filter(\.$isPublicProfile == true)
            .group(.or) { group in
                group.filter(\.$displayName, .custom("ILIKE"), "%\(query)%")
                group.filter(\.$firstName, .custom("ILIKE"), "%\(query)%")
                group.filter(\.$lastName, .custom("ILIKE"), "%\(query)%")
            }
            .range(..<20)
            .all()

        var results: [SocialProfileResponse] = []
        for athlete in athletes {
            let userId = athlete.$user.id
            let stats = try await aggregateStats(userId: userId, on: req.db)
            let user = try await UserModel.find(userId, on: req.db)
            results.append(SocialProfileResponse(
                from: athlete,
                userId: userId,
                totalDistanceKm: stats.distance,
                totalElevationGainM: stats.elevation,
                totalRuns: stats.count,
                joinedDate: user?.createdAt ?? Date()
            ))
        }

        return results
    }

    // MARK: - Helpers

    private func aggregateStats(userId: UUID, on db: Database) async throws -> (distance: Double, elevation: Double, count: Int) {
        let runs = try await RunModel.query(on: db)
            .filter(\.$user.$id == userId)
            .all()

        let totalDistance = runs.reduce(0.0) { $0 + $1.distanceKm }
        let totalElevation = runs.reduce(0.0) { $0 + $1.elevationGainM }
        return (distance: totalDistance, elevation: totalElevation, count: runs.count)
    }
}
