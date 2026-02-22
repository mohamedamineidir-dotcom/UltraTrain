import Vapor
import Fluent

struct RunController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(UserAuthMiddleware())
        protected.post("runs", use: uploadRun)
        protected.get("runs", use: listRuns)
        protected.get("runs", ":runId", use: getRun)
    }

    @Sendable
    func uploadRun(req: Request) async throws -> Response {
        let body = try req.content.decode(RunUploadRequest.self)
        let userId = try req.userId

        // Idempotency check — if a run with this key already exists, return 200
        let existing = try await RunModel.query(on: req.db)
            .filter(\.$idempotencyKey == body.idempotencyKey)
            .filter(\.$user.$id == userId)
            .first()

        if let existingRun = existing {
            let response = RunResponse(from: existingRun)
            return try await response.encodeResponse(status: .ok, for: req)
        }

        let formatter = ISO8601DateFormatter()
        guard let runDate = formatter.date(from: body.date) else {
            throw Abort(.badRequest, reason: "Invalid date format. Use ISO8601.")
        }

        let gpsTrackJSON = try encodeJSON(body.gpsTrack)
        let splitsJSON = try encodeJSON(body.splits)

        let run = RunModel()
        if let runId = UUID(uuidString: body.id) {
            run.id = runId
        }
        run.$user.id = userId
        run.date = runDate
        run.distanceKm = body.distanceKm
        run.elevationGainM = body.elevationGainM
        run.elevationLossM = body.elevationLossM
        run.duration = body.duration
        run.averageHeartRate = body.averageHeartRate
        run.maxHeartRate = body.maxHeartRate
        run.averagePaceSecondsPerKm = body.averagePaceSecondsPerKm
        run.gpsTrackJSON = gpsTrackJSON
        run.splitsJSON = splitsJSON
        run.notes = body.notes
        run.idempotencyKey = body.idempotencyKey

        try await run.save(on: req.db)
        let response = RunResponse(from: run)
        return try await response.encodeResponse(status: .created, for: req)
    }

    @Sendable
    func listRuns(req: Request) async throws -> [RunResponse] {
        let userId = try req.userId

        var query = RunModel.query(on: req.db)
            .filter(\.$user.$id == userId)
            .sort(\.$date, .descending)

        if let sinceStr = req.query[String.self, at: "since"],
           let since = ISO8601DateFormatter().date(from: sinceStr) {
            query = query.filter(\.$date >= since)
        }

        let limit = req.query[Int.self, at: "limit"] ?? 100
        let runs = try await query.range(..<limit).all()

        return runs.map { RunResponse(from: $0) }
    }

    @Sendable
    func getRun(req: Request) async throws -> RunResponse {
        let userId = try req.userId

        guard let runIdStr = req.parameters.get("runId"),
              let runId = UUID(uuidString: runIdStr) else {
            throw Abort(.badRequest, reason: "Invalid run ID")
        }

        guard let run = try await RunModel.query(on: req.db)
            .filter(\.$id == runId)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Run not found")
        }

        return RunResponse(from: run)
    }

    // MARK: - Helpers

    private func encodeJSON<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw Abort(.internalServerError, reason: "Failed to encode JSON")
        }
        return string
    }
}
