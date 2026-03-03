import Vapor
import Fluent

struct FinishEstimateController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(UserAuthMiddleware())
            .grouped(RateLimitMiddleware(maxRequests: 10, windowSeconds: 60))
        protected.put("finish-estimates", use: upsertEstimate)
        protected.get("finish-estimates", use: listEstimates)
        protected.delete("finish-estimates", ":estimateId", use: deleteEstimate)
    }

    @Sendable
    func upsertEstimate(req: Request) async throws -> Response {
        try FinishEstimateUpsertRequest.validate(content: req)
        let body = try req.content.decode(FinishEstimateUpsertRequest.self)
        let userId = try req.userId

        let existing = try await FinishEstimateModel.query(on: req.db)
            .filter(\.$estimateId == body.estimateId)
            .filter(\.$user.$id == userId)
            .first()

        if let estimate = existing {
            let formatter = ISO8601DateFormatter()
            // Conflict detection
            if let clientUpdatedAtStr = body.clientUpdatedAt,
               let clientUpdatedAt = formatter.date(from: clientUpdatedAtStr),
               let serverUpdatedAt = estimate.updatedAt,
               serverUpdatedAt > clientUpdatedAt {
                throw Abort(.conflict, reason: "Finish estimate was modified on another device. Please refresh and try again.")
            }

            estimate.raceId = body.raceId
            estimate.expectedTime = body.expectedTime
            estimate.confidencePercent = body.confidencePercent
            estimate.estimateJSON = body.estimateJson
            estimate.idempotencyKey = body.idempotencyKey
            try await estimate.save(on: req.db)
            let response = FinishEstimateResponse(from: estimate)
            return try await response.encodeResponse(status: .ok, for: req)
        }

        let estimate = FinishEstimateModel()
        estimate.$user.id = userId
        estimate.estimateId = body.estimateId
        estimate.raceId = body.raceId
        estimate.expectedTime = body.expectedTime
        estimate.confidencePercent = body.confidencePercent
        estimate.estimateJSON = body.estimateJson
        estimate.idempotencyKey = body.idempotencyKey
        try await estimate.save(on: req.db)
        let response = FinishEstimateResponse(from: estimate)
        return try await response.encodeResponse(status: .created, for: req)
    }

    @Sendable
    func listEstimates(req: Request) async throws -> PaginatedResponse<FinishEstimateResponse> {
        let userId = try req.userId
        let formatter = ISO8601DateFormatter()

        var query = FinishEstimateModel.query(on: req.db)
            .filter(\.$user.$id == userId)
            .sort(\.$createdAt, .descending)

        if let cursorStr = req.query[String.self, at: "cursor"],
           let cursorDate = formatter.date(from: cursorStr) {
            query = query.filter(\.$createdAt < cursorDate)
        }

        let requestedLimit = req.query[Int.self, at: "limit"] ?? 20
        let limit = min(max(requestedLimit, 1), 100)
        let estimates = try await query.range(..<(limit + 1)).all()

        let hasMore = estimates.count > limit
        let pageEstimates = hasMore ? Array(estimates.prefix(limit)) : estimates
        let items = pageEstimates.map { FinishEstimateResponse(from: $0) }
        let nextCursor = hasMore ? pageEstimates.last.flatMap { $0.createdAt.map { formatter.string(from: $0) } } : nil

        return PaginatedResponse(items: items, nextCursor: nextCursor, hasMore: hasMore)
    }

    @Sendable
    func deleteEstimate(req: Request) async throws -> HTTPStatus {
        let userId = try req.userId

        guard let idStr = req.parameters.get("estimateId"),
              let estimateId = UUID(uuidString: idStr) else {
            throw Abort(.badRequest, reason: "Invalid estimate ID")
        }

        guard let estimate = try await FinishEstimateModel.query(on: req.db)
            .filter(\.$id == estimateId)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Finish estimate not found")
        }

        try await estimate.delete(on: req.db)
        return .noContent
    }
}
