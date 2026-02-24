import Vapor
import Fluent

struct SharedRunController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(UserAuthMiddleware())
        protected.post("shared-runs", use: shareRun)
        protected.get("shared-runs", use: listSharedWithMe)
        protected.get("shared-runs", "mine", use: listMySharedRuns)
        protected.delete("shared-runs", ":sharedRunId", use: revokeShare)
    }

    @Sendable
    func shareRun(req: Request) async throws -> Response {
        try ShareRunRequest.validate(content: req)
        let body = try req.content.decode(ShareRunRequest.self)
        let userId = try req.userId

        // Validate array sizes
        guard body.gpsTrack.count <= 100_000 else {
            throw Abort(.badRequest, reason: "GPS track exceeds maximum of 100,000 points")
        }
        guard body.splits.count <= 1_000 else {
            throw Abort(.badRequest, reason: "Splits exceed maximum of 1,000 entries")
        }

        // Idempotency check
        let existing = try await SharedRunModel.query(on: req.db)
            .filter(\.$idempotencyKey == body.idempotencyKey)
            .filter(\.$user.$id == userId)
            .first()

        if let existingRun = existing {
            let displayName = try await getDisplayName(userId: userId, on: req.db)
            let response = SharedRunResponse(from: existingRun, displayName: displayName)
            return try await response.encodeResponse(status: .ok, for: req)
        }

        // Validate recipients are accepted friends
        let recipientIds = body.recipientProfileIds.compactMap { UUID(uuidString: $0) }
        guard !recipientIds.isEmpty else {
            throw Abort(.badRequest, reason: "At least one recipient is required")
        }

        for recipientId in recipientIds {
            let isFriend = try await FriendConnectionModel.query(on: req.db)
                .group(.or) { group in
                    group.group(.and) { and in
                        and.filter(\.$requestor.$id == userId)
                        and.filter(\.$recipient.$id == recipientId)
                    }
                    group.group(.and) { and in
                        and.filter(\.$requestor.$id == recipientId)
                        and.filter(\.$recipient.$id == userId)
                    }
                }
                .filter(\.$status == "accepted")
                .first() != nil

            guard isFriend else {
                throw Abort(.badRequest, reason: "Can only share runs with accepted friends")
            }
        }

        let formatter = ISO8601DateFormatter()
        guard let runDate = formatter.date(from: body.date) else {
            throw Abort(.badRequest, reason: "Invalid date format. Use ISO8601.")
        }

        // Encode GPS track and splits as JSON
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let gpsTrackJSON = String(data: try encoder.encode(body.gpsTrack), encoding: .utf8) ?? "[]"
        let splitsJSON = String(data: try encoder.encode(body.splits), encoding: .utf8) ?? "[]"

        let sharedRun = SharedRunModel()
        if let runId = UUID(uuidString: body.id) {
            sharedRun.id = runId
        }
        sharedRun.$user.id = userId
        sharedRun.date = runDate
        sharedRun.distanceKm = body.distanceKm
        sharedRun.elevationGainM = body.elevationGainM
        sharedRun.elevationLossM = body.elevationLossM
        sharedRun.duration = body.duration
        sharedRun.averagePace = body.averagePace
        sharedRun.gpsTrackJSON = gpsTrackJSON
        sharedRun.splitsJSON = splitsJSON
        sharedRun.notes = body.notes
        sharedRun.sharedAt = Date()
        sharedRun.idempotencyKey = body.idempotencyKey
        try await sharedRun.save(on: req.db)

        // Create recipient entries
        for recipientId in recipientIds {
            let recipient = SharedRunRecipientModel()
            recipient.$sharedRun.id = sharedRun.id!
            recipient.$recipient.id = recipientId
            try await recipient.save(on: req.db)
        }

        let displayName = try await getDisplayName(userId: userId, on: req.db)
        let response = SharedRunResponse(from: sharedRun, displayName: displayName)
        return try await response.encodeResponse(status: .created, for: req)
    }

    @Sendable
    func listSharedWithMe(req: Request) async throws -> [SharedRunResponse] {
        let userId = try req.userId
        let limit = req.query[Int.self, at: "limit"] ?? 20

        let recipientEntries = try await SharedRunRecipientModel.query(on: req.db)
            .filter(\.$recipient.$id == userId)
            .all()

        let sharedRunIds = recipientEntries.map { $0.$sharedRun.id }

        guard !sharedRunIds.isEmpty else { return [] }

        let runs = try await SharedRunModel.query(on: req.db)
            .filter(\.$id ~~ sharedRunIds)
            .sort(\.$sharedAt, .descending)
            .range(..<limit)
            .all()

        var responses: [SharedRunResponse] = []
        for run in runs {
            let displayName = try await getDisplayName(userId: run.$user.id, on: req.db)
            responses.append(SharedRunResponse(from: run, displayName: displayName))
        }
        return responses
    }

    @Sendable
    func listMySharedRuns(req: Request) async throws -> [SharedRunResponse] {
        let userId = try req.userId

        let runs = try await SharedRunModel.query(on: req.db)
            .filter(\.$user.$id == userId)
            .sort(\.$sharedAt, .descending)
            .all()

        let displayName = try await getDisplayName(userId: userId, on: req.db)
        return runs.map { SharedRunResponse(from: $0, displayName: displayName) }
    }

    @Sendable
    func revokeShare(req: Request) async throws -> HTTPStatus {
        let userId = try req.userId

        guard let idStr = req.parameters.get("sharedRunId"),
              let sharedRunId = UUID(uuidString: idStr) else {
            throw Abort(.badRequest, reason: "Invalid shared run ID")
        }

        guard let sharedRun = try await SharedRunModel.find(sharedRunId, on: req.db) else {
            throw Abort(.notFound, reason: "Shared run not found")
        }

        guard sharedRun.$user.id == userId else {
            throw Abort(.forbidden, reason: "Only the sharer can revoke")
        }

        // Delete recipients first (cascade should handle this, but be explicit)
        try await SharedRunRecipientModel.query(on: req.db)
            .filter(\.$sharedRun.$id == sharedRunId)
            .delete()

        try await sharedRun.delete(on: req.db)
        return .noContent
    }

    // MARK: - Helpers

    private func getDisplayName(userId: UUID, on db: Database) async throws -> String {
        if let athlete = try await AthleteModel.query(on: db)
            .filter(\.$user.$id == userId)
            .first() {
            return athlete.displayName.isEmpty ? "\(athlete.firstName) \(athlete.lastName)" : athlete.displayName
        }
        return "Unknown"
    }
}
