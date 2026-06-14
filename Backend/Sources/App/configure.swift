import Vapor
import Fluent
import FluentPostgresDriver
import JWT
import VaporAPNS
import APNSCore

struct APNSConfiguredKey: StorageKey {
    typealias Value = Bool
}

/// Rebuilds a valid PKCS#8 PEM from a `.p8` env var that may have lost its
/// newlines (single line) or carry literal "\n". Strips the markers and all
/// whitespace to the raw base64, then re-wraps at 64 chars with proper
/// BEGIN/END lines. Returns "" if there's no key body to work with.
func normalizeP8PEM(_ raw: String) -> String {
    let body = raw
        .replacingOccurrences(of: "\\n", with: "\n")
        .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
        .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
    let base64 = body.components(separatedBy: .whitespacesAndNewlines).joined()
    guard !base64.isEmpty else { return "" }
    var wrapped = ""
    var i = base64.startIndex
    while i < base64.endIndex {
        let j = base64.index(i, offsetBy: 64, limitedBy: base64.endIndex) ?? base64.endIndex
        wrapped += base64[i..<j] + "\n"
        i = j
    }
    return "-----BEGIN PRIVATE KEY-----\n" + wrapped + "-----END PRIVATE KEY-----"
}

func configure(_ app: Application) async throws {
    // MARK: - Database

    if let dbURL = Environment.get("DATABASE_URL") {
        app.logger.notice("DATABASE_URL found, configuring PostgreSQL")
        do {
            var postgresConfig = try SQLPostgresConfiguration(url: dbURL)
            // Railway internal Postgres doesn't require TLS
            postgresConfig.coreConfiguration.tls = .disable
            app.databases.use(
                DatabaseConfigurationFactory.postgres(configuration: postgresConfig),
                as: .psql
            )
            app.logger.notice("PostgreSQL configured successfully")
        } catch {
            app.logger.error("Failed to configure PostgreSQL: \(error)")
        }
    } else {
        app.logger.notice("No DATABASE_URL, using local PostgreSQL")
        app.databases.use(
            .postgres(configuration: .init(
                hostname: Environment.get("DB_HOST") ?? "localhost",
                port: 5432,
                username: Environment.get("DB_USER") ?? "ultratrain",
                password: Environment.get("DB_PASSWORD") ?? "password",
                database: Environment.get("DB_NAME") ?? "ultratrain_dev",
                tls: .disable
            )),
            as: .psql
        )
    }

    // MARK: - Migrations

    app.migrations.add(CreateUser())
    app.migrations.add(CreateAthlete())
    app.migrations.add(CreateRun())
    app.migrations.add(AddDeviceTokenToUser())
    app.migrations.add(CreateTrainingPlan())
    app.migrations.add(CreateRace())
    app.migrations.add(AddLinkedSessionToRun())
    app.migrations.add(AddPasswordResetToUser())
    app.migrations.add(AddUpdatedAtToRun())
    app.migrations.add(AddEmailVerificationToUser())
    app.migrations.add(AddSocialFieldsToAthlete())
    app.migrations.add(CreateFriendConnection())
    app.migrations.add(CreateActivityFeedItem())
    app.migrations.add(CreateFeedLike())
    app.migrations.add(CreateSharedRun())
    app.migrations.add(CreateSharedRunRecipient())
    app.migrations.add(CreateGroupChallenge())
    app.migrations.add(CreateChallengeParticipant())
    app.migrations.add(AddAPNSEnvironmentToUser())
    app.migrations.add(CreateCrashReport())
    app.migrations.add(CreateNutritionPlan())
    app.migrations.add(CreateFitnessSnapshot())
    app.migrations.add(CreateFinishEstimate())
    app.migrations.add(CreateChallenge())
    app.migrations.add(CreateAnalyticsEvent())
    app.migrations.add(AddReferralToUser())
    app.migrations.add(AddReferralRewardToUser())
    app.migrations.add(AddSocialAuthToUser())
    do {
        try await app.autoMigrate()
        app.logger.notice("Migrations completed successfully")
    } catch {
        app.logger.error("Migration failed: \(error)")
    }

    // MARK: - JWT

    let jwtSecret = Environment.get("JWT_SECRET")
    if app.environment == .production && jwtSecret == nil {
        fatalError("JWT_SECRET must be set in production")
    }
    app.jwt.signers.use(.hs256(key: jwtSecret ?? "dev-secret-change-in-production"))

    // MARK: - Content Coding

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601

    ContentConfiguration.global.use(encoder: encoder, for: .json)
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    // MARK: - Body Size Limit

    app.routes.defaultMaxBodySize = "10mb"

    // Outbound HTTP client timeout. OpenAI vision calls (AIController) can take
    // 15-30s, longer than the default, so allow a generous read window.
    app.http.client.configuration.timeout = .init(connect: .seconds(10), read: .seconds(60))

    // MARK: - Middleware

    let allowedOrigin: CORSMiddleware.AllowOriginSetting
    if let origin = Environment.get("CORS_ORIGIN") {
        allowedOrigin = .custom(origin)
    } else if app.environment == .production {
        allowedOrigin = .none
    } else {
        allowedOrigin = .all
    }

    app.middleware.use(SecurityHeadersMiddleware())
    app.middleware.use(RequestLoggingMiddleware())
    app.middleware.use(CORSMiddleware(configuration: .init(
        allowedOrigin: allowedOrigin,
        allowedMethods: [.GET, .POST, .PUT, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith,
                         .init("X-Signature"), .init("X-Timestamp"), .init("X-Client-Version")]
    )))

    // MARK: - APNs

    if let apnsKeyContent = Environment.get("APNS_KEY_CONTENT"),
       let apnsKeyId = Environment.get("APNS_KEY_ID"),
       let apnsTeamId = Environment.get("APNS_TEAM_ID") {
        // Rebuild a clean PEM no matter how the env var stored the .p8.
        // Pasting a multi-line key into Railway often collapses it to a single
        // line or stores literal "\n", which leaves the BEGIN header present
        // (so the old substring check passed) but the PEM structurally invalid
        // (so swift-crypto threw invalidPEMDocument). We strip the markers and
        // all whitespace down to the raw base64, then re-wrap at 64 chars with
        // proper headers — accepting any paste format.
        let pem = normalizeP8PEM(apnsKeyContent)
        if pem.isEmpty {
            app.logger.error("APNS_KEY_CONTENT has no usable key body. Push notifications disabled.")
        } else {
            do {
                app.apns.configure(
                    .jwt(
                        privateKey: try .loadFrom(string: pem),
                        keyIdentifier: apnsKeyId,
                        teamIdentifier: apnsTeamId
                    )
                )
                app.storage[APNSConfiguredKey.self] = true
                app.logger.notice("APNs configured successfully")
            } catch {
                app.logger.error("Failed to configure APNs: \(error). Verify APNS_KEY_CONTENT is the full .p8 file content (the base64 body between the BEGIN/END lines).")
            }
        }
    } else {
        app.logger.warning("APNs not configured — missing APNS_KEY_CONTENT, APNS_KEY_ID, or APNS_TEAM_ID")
    }

    // MARK: - Scheduled Jobs

    app.lifecycle.use(ScheduledJobService())

    // MARK: - Routes

    try routes(app)
}
