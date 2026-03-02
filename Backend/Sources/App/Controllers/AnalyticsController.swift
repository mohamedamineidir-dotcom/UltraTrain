import Vapor
import Fluent

struct AnalyticsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let analytics = routes.grouped("analytics")
            .grouped(RateLimitMiddleware(maxRequests: 20, windowSeconds: 60))
        analytics.post("events", use: ingestBatch)

        // Admin endpoints
        let admin = routes.grouped("admin", "analytics")
            .grouped(AdminTokenMiddleware())
        admin.get("stats", use: stats)
    }

    @Sendable
    func ingestBatch(req: Request) async throws -> HTTPStatus {
        let payload = try req.content.decode(AnalyticsBatchDTO.self)

        guard payload.events.count <= 100 else {
            throw Abort(.badRequest, reason: "Maximum 100 events per batch")
        }

        let models = payload.events.map { event -> AnalyticsEventModel in
            let propsJson: String?
            if !event.properties.isEmpty,
               let data = try? JSONEncoder().encode(event.properties) {
                propsJson = String(data: data, encoding: .utf8)
            } else {
                propsJson = nil
            }

            return AnalyticsEventModel(
                name: event.name,
                propertiesJson: propsJson,
                eventTimestamp: event.timestamp,
                appVersion: payload.appVersion,
                buildNumber: payload.buildNumber,
                platform: payload.platform,
                locale: payload.locale
            )
        }

        for model in models {
            try await model.save(on: req.db)
        }

        return .created
    }

    @Sendable
    func stats(req: Request) async throws -> AnalyticsStatsResponse {
        let totalCount = try await AnalyticsEventModel.query(on: req.db).count()

        let oneDayAgo = Date().addingTimeInterval(-86400)
        let last24hCount = try await AnalyticsEventModel.query(on: req.db)
            .filter(\.$eventTimestamp >= oneDayAgo)
            .count()

        let sevenDaysAgo = Date().addingTimeInterval(-604800)
        let last7dCount = try await AnalyticsEventModel.query(on: req.db)
            .filter(\.$eventTimestamp >= sevenDaysAgo)
            .count()

        return AnalyticsStatsResponse(
            totalEvents: totalCount,
            last24hEvents: last24hCount,
            last7dEvents: last7dCount
        )
    }
}

// MARK: - DTOs

struct AnalyticsBatchDTO: Content {
    let events: [AnalyticsBatchEventDTO]
    let appVersion: String
    let buildNumber: String
    let platform: String
    let locale: String
}

struct AnalyticsBatchEventDTO: Content {
    let name: String
    let properties: [String: String]
    let timestamp: Date
}

struct AnalyticsStatsResponse: Content {
    let totalEvents: Int
    let last24hEvents: Int
    let last7dEvents: Int
}
