import Vapor
import Fluent
import FluentPostgresDriver
import JWT
import NIOSSL

func configure(_ app: Application) async throws {
    // MARK: - Database

    if let dbURL = Environment.get("DATABASE_URL") {
        var tlsConfig = TLSConfiguration.makeClientConfiguration()
        tlsConfig.certificateVerification = .none
        let nioSSLContext = try NIOSSLContext(configuration: tlsConfig)

        var postgresConfig = try SQLPostgresConfiguration(url: dbURL)
        postgresConfig.coreConfiguration.tls = .require(nioSSLContext)
        app.databases.use(
            DatabaseConfigurationFactory.postgres(configuration: postgresConfig),
            as: .psql
        )
    } else {
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
    do {
        try await app.autoMigrate()
        app.logger.notice("Migrations completed successfully")
    } catch {
        app.logger.error("Migration failed: \(error)")
    }

    // MARK: - JWT

    let jwtSecret = Environment.get("JWT_SECRET") ?? "dev-secret-change-in-production"
    app.jwt.signers.use(.hs256(key: jwtSecret))

    // MARK: - Content Coding

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601

    ContentConfiguration.global.use(encoder: encoder, for: .json)
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    // MARK: - Middleware

    app.middleware.use(CORSMiddleware(configuration: .init(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )))

    // MARK: - Routes

    try routes(app)
}
