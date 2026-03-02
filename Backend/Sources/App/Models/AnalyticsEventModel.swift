import Fluent
import Vapor

final class AnalyticsEventModel: Model, @unchecked Sendable {
    static let schema = "analytics_events"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @OptionalField(key: "properties_json")
    var propertiesJson: String?

    @Field(key: "event_timestamp")
    var eventTimestamp: Date

    @Field(key: "app_version")
    var appVersion: String

    @Field(key: "build_number")
    var buildNumber: String

    @Field(key: "platform")
    var platform: String

    @Field(key: "locale")
    var locale: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        name: String,
        propertiesJson: String?,
        eventTimestamp: Date,
        appVersion: String,
        buildNumber: String,
        platform: String,
        locale: String
    ) {
        self.id = id
        self.name = name
        self.propertiesJson = propertiesJson
        self.eventTimestamp = eventTimestamp
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.platform = platform
        self.locale = locale
    }
}
