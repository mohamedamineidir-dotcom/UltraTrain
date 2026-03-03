import Vapor
import Fluent

struct NutritionController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(UserAuthMiddleware())
            .grouped(RateLimitMiddleware(maxRequests: 10, windowSeconds: 60))
        protected.put("nutrition", use: upsertNutrition)
        protected.get("nutrition", use: listNutrition)
        protected.delete("nutrition", ":nutritionId", use: deleteNutrition)
    }

    @Sendable
    func upsertNutrition(req: Request) async throws -> Response {
        try NutritionUpsertRequest.validate(content: req)
        let body = try req.content.decode(NutritionUpsertRequest.self)
        let userId = try req.userId

        let existing = try await NutritionPlanModel.query(on: req.db)
            .filter(\.$nutritionPlanId == body.nutritionPlanId)
            .filter(\.$user.$id == userId)
            .first()

        if let plan = existing {
            let formatter = ISO8601DateFormatter()
            // Conflict detection
            if let clientUpdatedAtStr = body.clientUpdatedAt,
               let clientUpdatedAt = formatter.date(from: clientUpdatedAtStr),
               let serverUpdatedAt = plan.updatedAt,
               serverUpdatedAt > clientUpdatedAt {
                throw Abort(.conflict, reason: "Nutrition plan was modified on another device. Please refresh and try again.")
            }

            plan.raceId = body.raceId
            plan.caloriesPerHour = body.caloriesPerHour
            plan.nutritionJSON = body.nutritionJson
            plan.idempotencyKey = body.idempotencyKey
            try await plan.save(on: req.db)
            let response = NutritionResponse(from: plan)
            return try await response.encodeResponse(status: .ok, for: req)
        }

        let plan = NutritionPlanModel()
        plan.$user.id = userId
        plan.nutritionPlanId = body.nutritionPlanId
        plan.raceId = body.raceId
        plan.caloriesPerHour = body.caloriesPerHour
        plan.nutritionJSON = body.nutritionJson
        plan.idempotencyKey = body.idempotencyKey
        try await plan.save(on: req.db)
        let response = NutritionResponse(from: plan)
        return try await response.encodeResponse(status: .created, for: req)
    }

    @Sendable
    func listNutrition(req: Request) async throws -> PaginatedResponse<NutritionResponse> {
        let userId = try req.userId
        let formatter = ISO8601DateFormatter()

        var query = NutritionPlanModel.query(on: req.db)
            .filter(\.$user.$id == userId)
            .sort(\.$createdAt, .descending)

        if let cursorStr = req.query[String.self, at: "cursor"],
           let cursorDate = formatter.date(from: cursorStr) {
            query = query.filter(\.$createdAt < cursorDate)
        }

        let requestedLimit = req.query[Int.self, at: "limit"] ?? 20
        let limit = min(max(requestedLimit, 1), 100)
        let plans = try await query.range(..<(limit + 1)).all()

        let hasMore = plans.count > limit
        let pagePlans = hasMore ? Array(plans.prefix(limit)) : plans
        let items = pagePlans.map { NutritionResponse(from: $0) }
        let nextCursor = hasMore ? pagePlans.last.flatMap { $0.createdAt.map { formatter.string(from: $0) } } : nil

        return PaginatedResponse(items: items, nextCursor: nextCursor, hasMore: hasMore)
    }

    @Sendable
    func deleteNutrition(req: Request) async throws -> HTTPStatus {
        let userId = try req.userId

        guard let idStr = req.parameters.get("nutritionId"),
              let nutritionId = UUID(uuidString: idStr) else {
            throw Abort(.badRequest, reason: "Invalid nutrition plan ID")
        }

        guard let plan = try await NutritionPlanModel.query(on: req.db)
            .filter(\.$id == nutritionId)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Nutrition plan not found")
        }

        try await plan.delete(on: req.db)
        return .noContent
    }
}
