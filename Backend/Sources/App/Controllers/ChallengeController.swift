import Vapor
import Fluent

struct ChallengeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(UserAuthMiddleware())
        protected.post("individual-challenges", use: createChallenge)
        protected.get("individual-challenges", use: listChallenges)
        protected.get("individual-challenges", ":challengeId", use: getChallenge)
        protected.put("individual-challenges", ":challengeId", "progress", use: updateProgress)
        protected.delete("individual-challenges", ":challengeId", use: deleteChallenge)
    }

    @Sendable
    func createChallenge(req: Request) async throws -> Response {
        try ChallengeCreateRequest.validate(content: req)
        let body = try req.content.decode(ChallengeCreateRequest.self)
        let userId = try req.userId

        // Idempotency check
        let existing = try await ChallengeModel.query(on: req.db)
            .filter(\.$idempotencyKey == body.idempotencyKey)
            .filter(\.$user.$id == userId)
            .first()

        if let existingChallenge = existing {
            let response = ChallengeResponse(from: existingChallenge)
            return try await response.encodeResponse(status: .ok, for: req)
        }

        let formatter = ISO8601DateFormatter()
        guard let startDate = formatter.date(from: body.startDate),
              let endDate = formatter.date(from: body.endDate) else {
            throw Abort(.badRequest, reason: "Invalid date format. Use ISO8601.")
        }

        guard endDate > startDate else {
            throw Abort(.badRequest, reason: "End date must be after start date")
        }

        let challenge = ChallengeModel()
        challenge.$user.id = userId
        challenge.name = body.name
        challenge.descriptionText = body.descriptionText
        challenge.type = body.type
        challenge.targetValue = body.targetValue
        challenge.currentValue = 0
        challenge.startDate = startDate
        challenge.endDate = endDate
        challenge.status = "active"
        challenge.idempotencyKey = body.idempotencyKey
        try await challenge.save(on: req.db)

        let response = ChallengeResponse(from: challenge)
        return try await response.encodeResponse(status: .created, for: req)
    }

    @Sendable
    func listChallenges(req: Request) async throws -> [ChallengeResponse] {
        let userId = try req.userId
        let statusFilter = req.query[String.self, at: "status"]

        var query = ChallengeModel.query(on: req.db)
            .filter(\.$user.$id == userId)
            .sort(\.$startDate, .descending)

        if let statusFilter {
            query = query.filter(\.$status == statusFilter)
        }

        let challenges = try await query.all()
        return challenges.map { ChallengeResponse(from: $0) }
    }

    @Sendable
    func getChallenge(req: Request) async throws -> ChallengeResponse {
        let userId = try req.userId
        let challenge = try await findChallenge(req: req, userId: userId)
        return ChallengeResponse(from: challenge)
    }

    @Sendable
    func updateProgress(req: Request) async throws -> ChallengeResponse {
        try ChallengeUpdateProgressRequest.validate(content: req)
        let body = try req.content.decode(ChallengeUpdateProgressRequest.self)
        let userId = try req.userId
        let challenge = try await findChallenge(req: req, userId: userId)

        guard challenge.status == "active" else {
            throw Abort(.badRequest, reason: "Challenge is not active")
        }

        challenge.currentValue = body.value
        try await challenge.save(on: req.db)

        return ChallengeResponse(from: challenge)
    }

    @Sendable
    func deleteChallenge(req: Request) async throws -> HTTPStatus {
        let userId = try req.userId
        let challenge = try await findChallenge(req: req, userId: userId)

        try await challenge.delete(on: req.db)
        return .noContent
    }

    // MARK: - Helpers

    private func findChallenge(req: Request, userId: UUID) async throws -> ChallengeModel {
        guard let idStr = req.parameters.get("challengeId"),
              let challengeId = UUID(uuidString: idStr) else {
            throw Abort(.badRequest, reason: "Invalid challenge ID")
        }

        guard let challenge = try await ChallengeModel.query(on: req.db)
            .filter(\.$id == challengeId)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Challenge not found")
        }

        return challenge
    }
}
