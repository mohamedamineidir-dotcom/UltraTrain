import Vapor
import Fluent

struct DeviceTokenController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(UserAuthMiddleware())
        protected.put("device-token", use: updateDeviceToken)
    }

    @Sendable
    func updateDeviceToken(req: Request) async throws -> DeviceTokenResponse {
        try DeviceTokenRequest.validate(content: req)
        let body = try req.content.decode(DeviceTokenRequest.self)
        let userId = try req.userId

        guard let user = try await UserModel.find(userId, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }

        user.deviceToken = body.deviceToken
        user.devicePlatform = body.platform
        try await user.save(on: req.db)

        return DeviceTokenResponse(message: "Device token updated")
    }
}
