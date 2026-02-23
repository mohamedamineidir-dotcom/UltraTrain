import Vapor
import Fluent

struct TrainingPlanController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(UserAuthMiddleware())
        protected.put("training-plan", use: upsertPlan)
        protected.get("training-plan", use: getPlan)
    }

    @Sendable
    func upsertPlan(req: Request) async throws -> Response {
        try TrainingPlanUploadRequest.validate(content: req)
        let body = try req.content.decode(TrainingPlanUploadRequest.self)
        let userId = try req.userId

        let formatter = ISO8601DateFormatter()
        guard let raceDate = formatter.date(from: body.targetRaceDate) else {
            throw Abort(.badRequest, reason: "Invalid date format. Use ISO8601.")
        }

        // Check for existing plan for this user
        let existing = try await TrainingPlanModel.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first()

        if let plan = existing {
            plan.targetRaceName = body.targetRaceName
            plan.targetRaceDate = raceDate
            plan.totalWeeks = body.totalWeeks
            plan.planJSON = body.planJson
            plan.idempotencyKey = body.idempotencyKey
            try await plan.save(on: req.db)
            let response = TrainingPlanResponse(from: plan)
            return try await response.encodeResponse(status: .ok, for: req)
        }

        let plan = TrainingPlanModel(
            userId: userId,
            targetRaceName: body.targetRaceName,
            targetRaceDate: raceDate,
            totalWeeks: body.totalWeeks,
            planJSON: body.planJson,
            idempotencyKey: body.idempotencyKey
        )
        try await plan.save(on: req.db)
        let response = TrainingPlanResponse(from: plan)
        return try await response.encodeResponse(status: .created, for: req)
    }

    @Sendable
    func getPlan(req: Request) async throws -> TrainingPlanResponse {
        let userId = try req.userId

        guard let plan = try await TrainingPlanModel.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "No training plan found")
        }

        return TrainingPlanResponse(from: plan)
    }
}
