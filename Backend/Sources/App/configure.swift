import Vapor
import Fluent
import FluentPostgresDriver
import JWT
import VaporAPNS
import APNSCore

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
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )))

    // MARK: - APNs

    if let apnsKeyContent = Environment.get("APNS_KEY_CONTENT"),
       let apnsKeyId = Environment.get("APNS_KEY_ID"),
       let apnsTeamId = Environment.get("APNS_TEAM_ID") {
        do {
            app.apns.configure(
                .jwt(
                    privateKey: try .loadFrom(string: apnsKeyContent),
                    keyIdentifier: apnsKeyId,
                    teamIdentifier: apnsTeamId
                )
            )
            app.logger.notice("APNs configured successfully")
        } catch {
            app.logger.error("Failed to configure APNs: \(error)")
        }
    } else {
        app.logger.warning("APNs not configured — missing APNS_KEY_CONTENT, APNS_KEY_ID, or APNS_TEAM_ID")
    }

    // MARK: - Scheduled Jobs

    app.lifecycle.use(ScheduledJobService())

    // MARK: - Routes

    try routes(app)
}
