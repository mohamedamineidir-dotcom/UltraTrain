import Vapor
import Fluent

struct RaceController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(UserAuthMiddleware())
        protected.put("races", use: upsertRace)
        protected.get("races", use: listRaces)
        protected.delete("races", ":raceId", use: deleteRace)
    }

    @Sendable
    func upsertRace(req: Request) async throws -> Response {
        try RaceUploadRequest.validate(content: req)
        let body = try req.content.decode(RaceUploadRequest.self)
        let userId = try req.userId

        let formatter = ISO8601DateFormatter()
        guard let raceDate = formatter.date(from: body.date) else {
            throw Abort(.badRequest, reason: "Invalid date format. Use ISO8601.")
        }

        let existing = try await RaceModel.query(on: req.db)
            .filter(\.$raceId == body.raceId)
            .filter(\.$user.$id == userId)
            .first()

        if let race = existing {
            // Conflict detection: if client sends clientUpdatedAt and server has a newer version, reject
            if let clientUpdatedAtStr = body.clientUpdatedAt,
               let clientUpdatedAt = formatter.date(from: clientUpdatedAtStr),
               let serverUpdatedAt = race.updatedAt,
               serverUpdatedAt > clientUpdatedAt {
                throw Abort(.conflict, reason: "Race was modified on another device. Please refresh and try again.")
            }

            race.name = body.name
            race.date = raceDate
            race.distanceKm = body.distanceKm
            race.elevationGainM = body.elevationGainM
            race.priority = body.priority
            race.raceJSON = body.raceJson
            race.idempotencyKey = body.idempotencyKey
            try await race.save(on: req.db)
            let response = RaceResponse(from: race)
            return try await response.encodeResponse(status: .ok, for: req)
        }

        let race = RaceModel()
        race.$user.id = userId
        race.raceId = body.raceId
        race.name = body.name
        race.date = raceDate
        race.distanceKm = body.distanceKm
        race.elevationGainM = body.elevationGainM
        race.priority = body.priority
        race.raceJSON = body.raceJson
        race.idempotencyKey = body.idempotencyKey
        try await race.save(on: req.db)
        let response = RaceResponse(from: race)
        return try await response.encodeResponse(status: .created, for: req)
    }

    @Sendable
    func listRaces(req: Request) async throws -> PaginatedResponse<RaceResponse> {
        let userId = try req.userId
        let formatter = ISO8601DateFormatter()

        var query = RaceModel.query(on: req.db)
            .filter(\.$user.$id == userId)
            .sort(\.$date, .ascending)

        if let cursorStr = req.query[String.self, at: "cursor"],
           let cursorDate = formatter.date(from: cursorStr) {
            query = query.filter(\.$date > cursorDate)
        }

        let requestedLimit = req.query[Int.self, at: "limit"] ?? 20
        let limit = min(max(requestedLimit, 1), 100)
        let races = try await query.range(..<(limit + 1)).all()

        let hasMore = races.count > limit
        let pageRaces = hasMore ? Array(races.prefix(limit)) : races
        let items = pageRaces.map { RaceResponse(from: $0) }
        let nextCursor = hasMore ? pageRaces.last.map { formatter.string(from: $0.date) } : nil

        return PaginatedResponse(items: items, nextCursor: nextCursor, hasMore: hasMore)
    }

    @Sendable
    func deleteRace(req: Request) async throws -> HTTPStatus {
        let userId = try req.userId

        guard let raceIdStr = req.parameters.get("raceId") else {
            throw Abort(.badRequest, reason: "Missing race ID")
        }

        guard let race = try await RaceModel.query(on: req.db)
            .filter(\.$raceId == raceIdStr)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Race not found")
        }

        try await race.delete(on: req.db)
        return .noContent
    }
}
