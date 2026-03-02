import Fluent
import Vapor

final class CrashReportModel: Model, @unchecked Sendable {
    static let schema = "crash_reports"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "client_id")
    var clientId: UUID

    @Field(key: "timestamp")
    var timestamp: Date

    @Field(key: "error_type")
    var errorType: String

    @Field(key: "error_message")
    var errorMessage: String

    @Field(key: "stack_trace")
    var stackTrace: String

    @Field(key: "device_model")
    var deviceModel: String

    @Field(key: "os_version")
    var osVersion: String

    @Field(key: "app_version")
    var appVersion: String

    @Field(key: "build_number")
    var buildNumber: String

    @OptionalField(key: "context_json")
    var contextJson: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        clientId: UUID,
        timestamp: Date,
        errorType: String,
        errorMessage: String,
        stackTrace: String,
        deviceModel: String,
        osVersion: String,
        appVersion: String,
        buildNumber: String,
        contextJson: String? = nil
    ) {
        self.id = id
        self.clientId = clientId
        self.timestamp = timestamp
        self.errorType = errorType
        self.errorMessage = errorMessage
        self.stackTrace = stackTrace
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.contextJson = contextJson
    }
}
