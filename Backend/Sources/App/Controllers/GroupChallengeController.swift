import Vapor
import Fluent

struct GroupChallengeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(UserAuthMiddleware())
        protected.post("challenges", use: createChallenge)
        protected.get("challenges", use: listChallenges)
        protected.get("challenges", ":challengeId", use: getChallenge)
        protected.post("challenges", ":challengeId", "join", use: joinChallenge)
        protected.post("challenges", ":challengeId", "leave", use: leaveChallenge)
        protected.put("challenges", ":challengeId", "progress", use: updateProgress)
    }

    @Sendable
    func createChallenge(req: Request) async throws -> Response {
        try CreateChallengeRequest.validate(content: req)
        let body = try req.content.decode(CreateChallengeRequest.self)
        let userId = try req.userId

        // Idempotency check
        let existing = try await GroupChallengeModel.query(on: req.db)
            .filter(\.$idempotencyKey == body.idempotencyKey)
            .filter(\.$creator.$id == userId)
            .first()

        if let existingChallenge = existing {
            let participants = try await ChallengeParticipantModel.query(on: req.db)
                .filter(\.$challenge.$id == existingChallenge.id!)
                .all()
            let displayName = try await getDisplayName(userId: userId, on: req.db)
            let response = GroupChallengeResponse(from: existingChallenge, creatorDisplayName: displayName, participants: participants)
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

        let challenge = GroupChallengeModel()
        challenge.$creator.id = userId
        challenge.name = body.name
        challenge.descriptionText = body.descriptionText
        challenge.type = body.type
        challenge.targetValue = body.targetValue
        challenge.startDate = startDate
        challenge.endDate = endDate
        challenge.status = "active"
        challenge.idempotencyKey = body.idempotencyKey
        try await challenge.save(on: req.db)

        // Auto-add creator as first participant
        let displayName = try await getDisplayName(userId: userId, on: req.db)
        let participant = ChallengeParticipantModel()
        participant.$challenge.id = challenge.id!
        participant.$user.id = userId
        participant.displayName = displayName
        participant.currentValue = 0
        participant.joinedDate = Date()
        try await participant.save(on: req.db)

        let response = GroupChallengeResponse(from: challenge, creatorDisplayName: displayName, participants: [participant])
        return try await response.encodeResponse(status: .created, for: req)
    }

    @Sendable
    func listChallenges(req: Request) async throws -> [GroupChallengeResponse] {
        let userId = try req.userId
        let statusFilter = req.query[String.self, at: "status"]

        // Find challenges where user is a participant
        let participations = try await ChallengeParticipantModel.query(on: req.db)
            .filter(\.$user.$id == userId)
            .all()

        let challengeIds = participations.map { $0.$challenge.id }
        guard !challengeIds.isEmpty else { return [] }

        var query = GroupChallengeModel.query(on: req.db)
            .filter(\.$id ~~ challengeIds)
            .sort(\.$startDate, .descending)

        if let statusFilter {
            query = query.filter(\.$status == statusFilter)
        }

        let challenges = try await query.all()

        var responses: [GroupChallengeResponse] = []
        for challenge in challenges {
            let participants = try await ChallengeParticipantModel.query(on: req.db)
                .filter(\.$challenge.$id == challenge.id!)
                .all()
            let creatorDisplayName = try await getDisplayName(userId: challenge.$creator.id, on: req.db)
            responses.append(GroupChallengeResponse(from: challenge, creatorDisplayName: creatorDisplayName, participants: participants))
        }
        return responses
    }

    @Sendable
    func getChallenge(req: Request) async throws -> GroupChallengeResponse {
        let challenge = try await findChallenge(req: req)

        let participants = try await ChallengeParticipantModel.query(on: req.db)
            .filter(\.$challenge.$id == challenge.id!)
            .all()
        let creatorDisplayName = try await getDisplayName(userId: challenge.$creator.id, on: req.db)
        return GroupChallengeResponse(from: challenge, creatorDisplayName: creatorDisplayName, participants: participants)
    }

    @Sendable
    func joinChallenge(req: Request) async throws -> GroupChallengeResponse {
        let userId = try req.userId
        let challenge = try await findChallenge(req: req)

        guard challenge.status == "active" else {
            throw Abort(.badRequest, reason: "Challenge is not active")
        }

        // Check not already a participant
        let existing = try await ChallengeParticipantModel.query(on: req.db)
            .filter(\.$challenge.$id == challenge.id!)
            .filter(\.$user.$id == userId)
            .first()

        guard existing == nil else {
            throw Abort(.conflict, reason: "Already a participant")
        }

        let displayName = try await getDisplayName(userId: userId, on: req.db)
        let participant = ChallengeParticipantModel()
        participant.$challenge.id = challenge.id!
        participant.$user.id = userId
        participant.displayName = displayName
        participant.currentValue = 0
        participant.joinedDate = Date()
        try await participant.save(on: req.db)

        let participants = try await ChallengeParticipantModel.query(on: req.db)
            .filter(\.$challenge.$id == challenge.id!)
            .all()
        let creatorDisplayName = try await getDisplayName(userId: challenge.$creator.id, on: req.db)
        return GroupChallengeResponse(from: challenge, creatorDisplayName: creatorDisplayName, participants: participants)
    }

    @Sendable
    func leaveChallenge(req: Request) async throws -> HTTPStatus {
        let userId = try req.userId
        let challenge = try await findChallenge(req: req)

        // Creator cannot leave their own challenge
        guard challenge.$creator.id != userId else {
            throw Abort(.badRequest, reason: "Creator cannot leave their own challenge")
        }

        guard let participant = try await ChallengeParticipantModel.query(on: req.db)
            .filter(\.$challenge.$id == challenge.id!)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Not a participant")
        }

        try await participant.delete(on: req.db)
        return .noContent
    }

    @Sendable
    func updateProgress(req: Request) async throws -> ChallengeParticipantResponse {
        try UpdateProgressRequest.validate(content: req)
        let body = try req.content.decode(UpdateProgressRequest.self)
        let userId = try req.userId
        let challenge = try await findChallenge(req: req)

        guard challenge.status == "active" else {
            throw Abort(.badRequest, reason: "Challenge is not active")
        }

        guard let participant = try await ChallengeParticipantModel.query(on: req.db)
            .filter(\.$challenge.$id == challenge.id!)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Not a participant in this challenge")
        }

        participant.currentValue = body.value
        try await participant.save(on: req.db)

        return ChallengeParticipantResponse(from: participant)
    }

    // MARK: - Helpers

    private func findChallenge(req: Request) async throws -> GroupChallengeModel {
        guard let idStr = req.parameters.get("challengeId"),
              let challengeId = UUID(uuidString: idStr) else {
            throw Abort(.badRequest, reason: "Invalid challenge ID")
        }

        guard let challenge = try await GroupChallengeModel.find(challengeId, on: req.db) else {
            throw Abort(.notFound, reason: "Challenge not found")
        }

        return challenge
    }

    private func getDisplayName(userId: UUID, on db: Database) async throws -> String {
        if let athlete = try await AthleteModel.query(on: db)
            .filter(\.$user.$id == userId)
            .first() {
            return athlete.displayName.isEmpty ? "\(athlete.firstName) \(athlete.lastName)" : athlete.displayName
        }
        return "Unknown"
    }
}
