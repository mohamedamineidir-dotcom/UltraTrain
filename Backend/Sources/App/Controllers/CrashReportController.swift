import Vapor
import Fluent

struct CrashReportController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let crashes = routes.grouped("crashes")
            .grouped(RateLimitMiddleware(maxRequests: 10, windowSeconds: 60))
        crashes.post(use: create)
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
}
