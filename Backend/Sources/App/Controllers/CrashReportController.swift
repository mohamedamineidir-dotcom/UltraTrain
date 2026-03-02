import Vapor
import Fluent

struct CrashReportController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let crashes = routes.grouped("crashes")
            .grouped(RateLimitMiddleware(maxRequests: 10, windowSeconds: 60))
        crashes.post(use: create)

        // Admin endpoints — protected by ADMIN_TOKEN env var
        let admin = routes.grouped("admin", "crashes")
            .grouped(AdminTokenMiddleware())
        admin.get(use: list)
        admin.get("stats", use: stats)
        admin.delete(":crashId", use: delete)
    }

    @Sendable
    func create(req: Request) async throws -> HTTPStatus {
        try CrashReportDTO.validate(content: req)
        let dto = try req.content.decode(CrashReportDTO.self)

        let contextJson: String?
        if let context = dto.context, !context.isEmpty {
            let data = try JSONEncoder().encode(context)
            contextJson = String(data: data, encoding: .utf8)
        } else {
            contextJson = nil
        }

        let model = CrashReportModel(
            clientId: dto.id,
            timestamp: dto.timestamp,
            errorType: dto.errorType,
            errorMessage: dto.errorMessage,
            stackTrace: String(dto.stackTrace.prefix(10000)),
            deviceModel: dto.deviceModel,
            osVersion: dto.osVersion,
            appVersion: dto.appVersion,
            buildNumber: dto.buildNumber,
            contextJson: contextJson
        )

        try await model.save(on: req.db)
        return .created
    }

    @Sendable
    func list(req: Request) async throws -> Page<CrashReportResponse> {
        let errorType = req.query[String.self, at: "errorType"]
        let appVersion = req.query[String.self, at: "appVersion"]

        var query = CrashReportModel.query(on: req.db)
            .sort(\.$timestamp, .descending)

        if let errorType {
            query = query.filter(\.$errorType == errorType)
        }
        if let appVersion {
            query = query.filter(\.$appVersion == appVersion)
        }

        let page = try await query.paginate(for: req)
        return page.map { CrashReportResponse(from: $0) }
    }

    @Sendable
    func stats(req: Request) async throws -> CrashStatsResponse {
        let totalCount = try await CrashReportModel.query(on: req.db).count()

        let oneDayAgo = Date().addingTimeInterval(-86400)
        let last24hCount = try await CrashReportModel.query(on: req.db)
            .filter(\.$timestamp >= oneDayAgo)
            .count()

        let sevenDaysAgo = Date().addingTimeInterval(-604800)
        let last7dCount = try await CrashReportModel.query(on: req.db)
            .filter(\.$timestamp >= sevenDaysAgo)
            .count()

        let exceptionCount = try await CrashReportModel.query(on: req.db)
            .filter(\.$errorType == "exception")
            .count()
        let signalCount = try await CrashReportModel.query(on: req.db)
            .filter(\.$errorType == "signal")
            .count()
        let caughtCount = try await CrashReportModel.query(on: req.db)
            .filter(\.$errorType == "caught")
            .count()

        let recentCrashes = try await CrashReportModel.query(on: req.db)
            .sort(\.$timestamp, .descending)
            .range(..<10)
            .all()
            .map { CrashReportResponse(from: $0) }

        return CrashStatsResponse(
            totalCount: totalCount,
            last24hCount: last24hCount,
            last7dCount: last7dCount,
            byType: CrashTypeBreakdown(
                exception: exceptionCount,
                signal: signalCount,
                caught: caughtCount
            ),
            recentCrashes: recentCrashes
        )
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let crashId = req.parameters.get("crashId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid crash ID")
        }
        guard let model = try await CrashReportModel.find(crashId, on: req.db) else {
            throw Abort(.notFound)
        }
        try await model.delete(on: req.db)
        return .noContent
    }
}

struct CrashReportResponse: Content {
    let id: UUID
    let clientId: UUID
    let timestamp: Date
    let errorType: String
    let errorMessage: String
    let stackTrace: String
    let deviceModel: String
    let osVersion: String
    let appVersion: String
    let buildNumber: String
    let context: [String: String]?
    let createdAt: Date?

    init(from model: CrashReportModel) {
        self.id = model.id ?? UUID()
        self.clientId = model.clientId
        self.timestamp = model.timestamp
        self.errorType = model.errorType
        self.errorMessage = model.errorMessage
        self.stackTrace = model.stackTrace
        self.deviceModel = model.deviceModel
        self.osVersion = model.osVersion
        self.appVersion = model.appVersion
        self.buildNumber = model.buildNumber
        self.createdAt = model.createdAt
        if let json = model.contextJson,
           let data = json.data(using: .utf8),
           let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            self.context = dict
        } else {
            self.context = nil
        }
    }
}

struct CrashStatsResponse: Content {
    let totalCount: Int
    let last24hCount: Int
    let last7dCount: Int
    let byType: CrashTypeBreakdown
    let recentCrashes: [CrashReportResponse]
}

struct CrashTypeBreakdown: Content {
    let exception: Int
    let signal: Int
    let caught: Int
}
