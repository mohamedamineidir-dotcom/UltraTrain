@testable import App
import XCTVapor
import Fluent

final class DeviceTokenControllerTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = try await createTestApp()
    }

    override func tearDown() async throws {
        app.shutdown()
        app = nil
    }

    // MARK: - PUT /device-token

    func testUpdateDeviceToken_valid_returnsSuccess() async throws {
        let user = try await app.registerUser(email: "token@test.com", password: "password123")

        try await app.test(.PUT, "v1/device-token", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(DeviceTokenRequest(
                deviceToken: "abc123def456",
                platform: "ios",
                apnsEnvironment: "production"
            ))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let response = try res.content.decode(DeviceTokenResponse.self)
            XCTAssertEqual(response.message, "Device token updated")
        })

        // Verify stored in database
        let dbUser = try await UserModel.query(on: app.db)
            .filter(\.$email == "token@test.com")
            .first()
        XCTAssertEqual(dbUser?.deviceToken, "abc123def456")
        XCTAssertEqual(dbUser?.devicePlatform, "ios")
        XCTAssertEqual(dbUser?.apnsEnvironment, "production")
    }

    func testUpdateDeviceToken_androidPlatform_succeeds() async throws {
        let user = try await app.registerUser(email: "android@test.com", password: "password123")

        try await app.test(.PUT, "v1/device-token", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(DeviceTokenRequest(
                deviceToken: "fcm-token-xyz",
                platform: "android",
                apnsEnvironment: nil
            ))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        let dbUser = try await UserModel.query(on: app.db)
            .filter(\.$email == "android@test.com")
            .first()
        XCTAssertEqual(dbUser?.devicePlatform, "android")
    }

    func testUpdateDeviceToken_defaultApnsEnvironment_setsProduction() async throws {
        let user = try await app.registerUser(email: "defaultenv@test.com", password: "password123")

        try await app.test(.PUT, "v1/device-token", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(DeviceTokenRequest(
                deviceToken: "token123",
                platform: "ios",
                apnsEnvironment: nil
            ))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        let dbUser = try await UserModel.query(on: app.db)
            .filter(\.$email == "defaultenv@test.com")
            .first()
        XCTAssertEqual(dbUser?.apnsEnvironment, "production")
    }

    func testUpdateDeviceToken_updatesExisting() async throws {
        let user = try await app.registerUser(email: "update@test.com", password: "password123")

        // First update
        try await app.test(.PUT, "v1/device-token", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(DeviceTokenRequest(
                deviceToken: "old-token",
                platform: "ios",
                apnsEnvironment: nil
            ))
        }, afterResponse: { _ in })

        // Second update
        try await app.test(.PUT, "v1/device-token", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(DeviceTokenRequest(
                deviceToken: "new-token",
                platform: "ios",
                apnsEnvironment: "sandbox"
            ))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        let dbUser = try await UserModel.query(on: app.db)
            .filter(\.$email == "update@test.com")
            .first()
        XCTAssertEqual(dbUser?.deviceToken, "new-token")
        XCTAssertEqual(dbUser?.apnsEnvironment, "sandbox")
    }

    // MARK: - Validation

    func testUpdateDeviceToken_emptyToken_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "empty@test.com", password: "password123")

        try await app.test(.PUT, "v1/device-token", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(DeviceTokenRequest(
                deviceToken: "",
                platform: "ios",
                apnsEnvironment: nil
            ))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUpdateDeviceToken_invalidPlatform_returnsBadRequest() async throws {
        let user = try await app.registerUser(email: "badplatform@test.com", password: "password123")

        try await app.test(.PUT, "v1/device-token", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: user.accessToken!)
            try req.content.encode(DeviceTokenRequest(
                deviceToken: "token123",
                platform: "windows",
                apnsEnvironment: nil
            ))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    // MARK: - Auth

    func testUpdateDeviceToken_noAuth_returnsUnauthorized() async throws {
        try await app.test(.PUT, "v1/device-token", beforeRequest: { req in
            try req.content.encode(DeviceTokenRequest(
                deviceToken: "token123",
                platform: "ios",
                apnsEnvironment: nil
            ))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
}
