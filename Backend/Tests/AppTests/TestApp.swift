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
            .field("apns_environment", .string)
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
            .field("bio", .string)
            .field("is_public_profile", .bool, .required, .sql(.default(true)))
            .field("display_name", .string, .required, .sql(.default("")))
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

        // Crash Reports
        try await database.schema("crash_reports")
            .id()
            .field("client_id", .uuid, .required)
            .field("timestamp", .datetime, .required)
            .field("error_type", .string, .required)
            .field("error_message", .string, .required)
            .field("stack_trace", .string, .required)
            .field("device_model", .string, .required)
            .field("os_version", .string, .required)
            .field("app_version", .string, .required)
            .field("build_number", .string, .required)
            .field("context_json", .string)
            .field("created_at", .datetime)
            .create()

        // Friend Connections
        try await database.schema("friend_connections")
            .id()
            .field("requestor_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("recipient_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("status", .string, .required)
            .field("created_at", .datetime)
            .field("accepted_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "requestor_id", "recipient_id")
            .create()

        // Activity Feed Items
        try await database.schema("activity_feed_items")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("activity_type", .string, .required)
            .field("title", .string, .required)
            .field("subtitle", .string)
            .field("stats_json", .string)
            .field("timestamp", .datetime, .required)
            .field("idempotency_key", .string, .required)
            .field("created_at", .datetime)
            .unique(on: "idempotency_key", "user_id")
            .create()

        // Feed Likes
        try await database.schema("feed_likes")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("feed_item_id", .uuid, .required, .references("activity_feed_items", "id", onDelete: .cascade))
            .field("created_at", .datetime)
            .unique(on: "user_id", "feed_item_id")
            .create()

        // Shared Runs
        try await database.schema("shared_runs")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("source_run_id", .uuid)
            .field("date", .datetime, .required)
            .field("distance_km", .double, .required)
            .field("elevation_gain_m", .double, .required)
            .field("elevation_loss_m", .double, .required)
            .field("duration", .double, .required)
            .field("average_pace", .double, .required)
            .field("gps_track_json", .string, .required)
            .field("splits_json", .string, .required)
            .field("notes", .string)
            .field("shared_at", .datetime, .required)
            .field("idempotency_key", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "idempotency_key", "user_id")
            .create()

        // Shared Run Recipients
        try await database.schema("shared_run_recipients")
            .id()
            .field("shared_run_id", .uuid, .required, .references("shared_runs", "id", onDelete: .cascade))
            .field("recipient_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("created_at", .datetime)
            .unique(on: "shared_run_id", "recipient_id")
            .create()

        // Group Challenges
        try await database.schema("group_challenges")
            .id()
            .field("creator_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("name", .string, .required)
            .field("description_text", .string, .required)
            .field("type", .string, .required)
            .field("target_value", .double, .required)
            .field("start_date", .datetime, .required)
            .field("end_date", .datetime, .required)
            .field("status", .string, .required)
            .field("idempotency_key", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "idempotency_key", "creator_id")
            .create()

        // Challenge Participants
        try await database.schema("challenge_participants")
            .id()
            .field("challenge_id", .uuid, .required, .references("group_challenges", "id", onDelete: .cascade))
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("display_name", .string, .required)
            .field("current_value", .double, .required, .sql(.default(0)))
            .field("joined_date", .datetime, .required)
            .field("updated_at", .datetime)
            .unique(on: "challenge_id", "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("challenge_participants").delete()
        try await database.schema("group_challenges").delete()
        try await database.schema("shared_run_recipients").delete()
        try await database.schema("shared_runs").delete()
        try await database.schema("feed_likes").delete()
        try await database.schema("activity_feed_items").delete()
        try await database.schema("friend_connections").delete()
        try await database.schema("crash_reports").delete()
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

    /// Create an athlete profile for a registered user
    func createAthleteProfile(token: String, firstName: String = "Test", lastName: String = "Runner") async throws {
        try await self.test(.PUT, "v1/athlete", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: token)
            try req.content.encode(AthleteUpdateRequest(
                firstName: firstName,
                lastName: lastName,
                dateOfBirth: "1990-01-01T00:00:00Z",
                weightKg: 70.0,
                heightCm: 175.0,
                restingHeartRate: 55,
                maxHeartRate: 185,
                experienceLevel: "intermediate",
                weeklyVolumeKm: 60.0,
                longestRunKm: 42.0
            ))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
    }

    /// Get the user ID from the database for a given email
    func getUserId(email: String) async throws -> UUID {
        let user = try await UserModel.query(on: self.db)
            .filter(\.$email == email.lowercased())
            .first()
        return user!.id!
    }

    /// Send a friend request and accept it to establish a friendship between two users
    func establishFriendship(requestorToken: String, recipientToken: String, recipientUserId: UUID) async throws {
        // Send request
        var connectionId: String?
        try await self.test(.POST, "v1/friends/request", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: requestorToken)
            try req.content.encode(FriendRequestRequest(recipientProfileId: recipientUserId.uuidString))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            let conn = try res.content.decode(FriendConnectionResponse.self)
            connectionId = conn.id
        })

        // Accept request
        try await self.test(.PUT, "v1/friends/\(connectionId!)/accept", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: recipientToken)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
    }
}
