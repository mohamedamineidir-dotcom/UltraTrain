import Vapor
import Fluent

struct AthleteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(UserAuthMiddleware())
        protected.get("athlete", use: getAthlete)
        protected.put("athlete", use: updateAthlete)
    }

    @Sendable
    func getAthlete(req: Request) async throws -> AthleteResponse {
        let userId = try req.userId

        guard let athlete = try await AthleteModel.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "No athlete profile found")
        }

        return AthleteResponse(from: athlete)
    }

    @Sendable
    func updateAthlete(req: Request) async throws -> AthleteResponse {
        try AthleteUpdateRequest.validate(content: req)
        let body = try req.content.decode(AthleteUpdateRequest.self)
        let userId = try req.userId

        let formatter = ISO8601DateFormatter()
        guard let dateOfBirth = formatter.date(from: body.dateOfBirth) else {
            throw Abort(.badRequest, reason: "Invalid date format for dateOfBirth. Use ISO8601.")
        }

        let athlete: AthleteModel
        if let existing = try await AthleteModel.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first() {
            athlete = existing
        } else {
            athlete = AthleteModel()
            athlete.$user.id = userId
        }

        athlete.firstName = body.firstName
        athlete.lastName = body.lastName
        athlete.dateOfBirth = dateOfBirth
        athlete.weightKg = body.weightKg
        athlete.heightCm = body.heightCm
        athlete.restingHeartRate = body.restingHeartRate
        athlete.maxHeartRate = body.maxHeartRate
        athlete.experienceLevel = body.experienceLevel
        athlete.weeklyVolumeKm = body.weeklyVolumeKm
        athlete.longestRunKm = body.longestRunKm

        try await athlete.save(on: req.db)
        return AthleteResponse(from: athlete)
    }
}
