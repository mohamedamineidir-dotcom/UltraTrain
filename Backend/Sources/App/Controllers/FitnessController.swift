import Vapor
import Fluent

struct FitnessController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(UserAuthMiddleware())
            .grouped(RateLimitMiddleware(maxRequests: 10, windowSeconds: 60))
        protected.put("fitness-snapshots", use: upsertSnapshot)
        protected.get("fitness-snapshots", use: listSnapshots)
        protected.delete("fitness-snapshots", ":snapshotId", use: deleteSnapshot)
    }

    @Sendable
    func upsertSnapshot(req: Request) async throws -> Response {
        try FitnessSnapshotUpsertRequest.validate(content: req)
        let body = try req.content.decode(FitnessSnapshotUpsertRequest.self)
        let userId = try req.userId

        let formatter = ISO8601DateFormatter()
        guard let snapshotDate = formatter.date(from: body.date) else {
            throw Abort(.badRequest, reason: "Invalid date format. Use ISO8601.")
        }

        let existing = try await FitnessSnapshotModel.query(on: req.db)
            .filter(\.$snapshotId == body.snapshotId)
            .filter(\.$user.$id == userId)
            .first()

        if let snapshot = existing {
            // Conflict detection
            if let clientUpdatedAtStr = body.clientUpdatedAt,
               let clientUpdatedAt = formatter.date(from: clientUpdatedAtStr),
               let serverUpdatedAt = snapshot.updatedAt,
               serverUpdatedAt > clientUpdatedAt {
                throw Abort(.conflict, reason: "Fitness snapshot was modified on another device. Please refresh and try again.")
            }

            snapshot.date = snapshotDate
            snapshot.fitness = body.fitness
            snapshot.fatigue = body.fatigue
            snapshot.form = body.form
            snapshot.fitnessJSON = body.fitnessJson
            snapshot.idempotencyKey = body.idempotencyKey
            try await snapshot.save(on: req.db)
            let response = FitnessSnapshotResponse(from: snapshot)
            return try await response.encodeResponse(status: .ok, for: req)
        }

        let snapshot = FitnessSnapshotModel()
        snapshot.$user.id = userId
        snapshot.snapshotId = body.snapshotId
        snapshot.date = snapshotDate
        snapshot.fitness = body.fitness
        snapshot.fatigue = body.fatigue
        snapshot.form = body.form
        snapshot.fitnessJSON = body.fitnessJson
        snapshot.idempotencyKey = body.idempotencyKey
        try await snapshot.save(on: req.db)
        let response = FitnessSnapshotResponse(from: snapshot)
        return try await response.encodeResponse(status: .created, for: req)
    }

    @Sendable
    func listSnapshots(req: Request) async throws -> PaginatedResponse<FitnessSnapshotResponse> {
        let userId = try req.userId
        let formatter = ISO8601DateFormatter()

        var query = FitnessSnapshotModel.query(on: req.db)
            .filter(\.$user.$id == userId)
            .sort(\.$date, .descending)

        if let cursorStr = req.query[String.self, at: "cursor"],
           let cursorDate = formatter.date(from: cursorStr) {
            query = query.filter(\.$date < cursorDate)
        }

        let requestedLimit = req.query[Int.self, at: "limit"] ?? 100
        let limit = min(max(requestedLimit, 1), 500)
        let snapshots = try await query.range(..<(limit + 1)).all()

        let hasMore = snapshots.count > limit
        let pageSnapshots = hasMore ? Array(snapshots.prefix(limit)) : snapshots
        let items = pageSnapshots.map { FitnessSnapshotResponse(from: $0) }
        let nextCursor = hasMore ? pageSnapshots.last.map { formatter.string(from: $0.date) } : nil

        return PaginatedResponse(items: items, nextCursor: nextCursor, hasMore: hasMore)
    }

    @Sendable
    func deleteSnapshot(req: Request) async throws -> HTTPStatus {
        let userId = try req.userId

        guard let idStr = req.parameters.get("snapshotId"),
              let snapshotId = UUID(uuidString: idStr) else {
            throw Abort(.badRequest, reason: "Invalid snapshot ID")
        }

        guard let snapshot = try await FitnessSnapshotModel.query(on: req.db)
            .filter(\.$id == snapshotId)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Fitness snapshot not found")
        }

        try await snapshot.delete(on: req.db)
        return .noContent
    }
}
