import Foundation
import SwiftData

@Model
final class StravaUploadQueueSwiftDataModel {
    var id: UUID = UUID()
    var runId: UUID = UUID()
    var statusRaw: String = "pending"
    var retryCount: Int = 0
    var lastAttempt: Date?
    var stravaActivityId: Int?
    var errorMessage: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        runId: UUID = UUID(),
        statusRaw: String = "pending",
        retryCount: Int = 0,
        lastAttempt: Date? = nil,
        stravaActivityId: Int? = nil,
        errorMessage: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.runId = runId
        self.statusRaw = statusRaw
        self.retryCount = retryCount
        self.lastAttempt = lastAttempt
        self.stravaActivityId = stravaActivityId
        self.errorMessage = errorMessage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
