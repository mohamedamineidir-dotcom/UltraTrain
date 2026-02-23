import Foundation
import SwiftData

@Model
final class SyncQueueSwiftDataModel {
    var id: UUID = UUID()
    var runId: UUID = UUID()
    var operationTypeRaw: String = "runUpload"
    var entityId: UUID = UUID()
    var statusRaw: String = "pending"
    var retryCount: Int = 0
    var lastAttempt: Date?
    var errorMessage: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        runId: UUID = UUID(),
        operationTypeRaw: String = "runUpload",
        entityId: UUID = UUID(),
        statusRaw: String = "pending",
        retryCount: Int = 0,
        lastAttempt: Date? = nil,
        errorMessage: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.runId = runId
        self.operationTypeRaw = operationTypeRaw
        self.entityId = entityId
        self.statusRaw = statusRaw
        self.retryCount = retryCount
        self.lastAttempt = lastAttempt
        self.errorMessage = errorMessage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
