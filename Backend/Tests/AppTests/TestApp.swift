@testable import App
import XCTVapor
import Fluent
import FluentSQLiteDriver

func createTestApp() async throws -> Application {
    let app = Application(.testing)

    // In-memory SQLite
    app.databases.use(.sqlite(.memory), as: .sqlite)

    // Use a single combined migration for SQLite compatibility
    // (SQLite doesn't support adding multiple columns in one ALTER TABLE)
    app.migrations.add(CreateTestSchema())
    try await app.autoMigrate()

    // JWT
    app.jwt.signers.use(.hs256(key: "test-secret"))

    // JSON coding
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601

    ContentConfiguration.global.use(encoder: encoder, for: .json)
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    // Routes
    try routes(app)

    return app
}

// MARK: - Combined Test Migration

/// Creates all tables with their final schema in a single migration.
/// This avoids SQLite's limitation with ALTER TABLE ADD COLUMN.
struct CreateTestSchema: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Users (final schema with all fields)
        try await database.schema("users")
            .id()
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .field("refresh_token_hash", .string)
            .field("device_token", .string)
            .field("device_platform", .string)
            .field("reset_code_hash", .string)
            .field("reset_code_expires_at", .datetime)
            .field("is_email_verified", .bool, .required, .sql(.default(false)))
            .field("verification_code_hash", .string)
            .field("verification_code_expires_at", .datetime)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "email")
            .create()

        // Athletes
        try await database.schema("athletes")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .field("date_of_birth", .datetime, .required)
            .field("weight_kg", .double, .required)
            .field("height_cm", .double, .required)
            .field("resting_heart_rate", .int, .required)
            .field("max_heart_rate", .int, .required)
            .field("experience_level", .string, .required)
            .field("weekly_volume_km", .double, .required)
            .field("longest_run_km", .double, .required)
            .field("updated_at", .datetime)
            .unique(on: "user_id")
            .create()

        // Runs (final schema)
        try await database.schema("runs")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("date", .datetime, .required)
            .field("distance_km", .double, .required)
            .field("elevation_gain_m", .double, .required)
            .field("elevation_loss_m", .double, .required)
            .field("duration", .double, .required)
            .field("average_heart_rate", .int)
            .field("max_heart_rate", .int)
            .field("average_pace_seconds_per_km", .double, .required)
            .field("gps_track_json", .string, .required)
            .field("splits_json", .string, .required)
            .field("notes", .string)
            .field("idempotency_key", .string, .required)
            .field("linked_session_id", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "idempotency_key", "user_id")
            .create()

        // Training Plans
        try await database.schema("training_plans")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("target_race_name", .string, .required)
            .field("target_race_date", .datetime, .required)
            .field("total_weeks", .int, .required)
            .field("plan_json", .string, .required)
            .field("idempotency_key", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "user_id")
            .unique(on: "idempotency_key", "user_id")
            .create()

        // Races
        try await database.schema("races")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("race_id", .string, .required)
            .field("name", .string, .required)
            .field("date", .datetime, .required)
            .field("distance_km", .double, .required)
            .field("elevation_gain_m", .double, .required)
            .field("priority", .string, .required)
            .field("race_json", .string, .required)
            .field("idempotency_key", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "race_id", "user_id")
            .unique(on: "idempotency_key", "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("races").delete()
        try await database.schema("training_plans").delete()
        try await database.schema("runs").delete()
        try await database.schema("athletes").delete()
        try await database.schema("users").delete()
    }
}

// MARK: - Test Helpers

struct TestUser {
    let email: String
    let password: String
    var accessToken: String?
    var refreshToken: String?
}

extension Application {
    /// Register a user and return tokens
    @discardableResult
    func registerUser(email: String = "test@example.com", password: String = "password123") async throws -> TestUser {
        var user = TestUser(email: email, password: password)

        try await self.test(.POST, "v1/auth/register", beforeRequest: { req in
            try req.content.encode(RegisterRequest(email: email, password: password))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let tokens = try res.content.decode(TokenResponse.self)
            user.accessToken = tokens.accessToken
            user.refreshToken = tokens.refreshToken
        })

        return user
    }

    /// Login and return tokens
    @discardableResult
    func loginUser(email: String = "test@example.com", password: String = "password123") async throws -> TestUser {
        var user = TestUser(email: email, password: password)

        try await self.test(.POST, "v1/auth/login", beforeRequest: { req in
            try req.content.encode(LoginRequest(email: email, password: password))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let tokens = try res.content.decode(TokenResponse.self)
            user.accessToken = tokens.accessToken
            user.refreshToken = tokens.refreshToken
        })

        return user
    }
}
