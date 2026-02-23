import Foundation

enum SyncQueueMapper {

    static func toDomain(_ model: SyncQueueSwiftDataModel) -> SyncQueueItem? {
        guard let status = SyncQueueItemStatus(rawValue: model.statusRaw) else { return nil }
        return SyncQueueItem(
            id: model.id,
            runId: model.runId,
            status: status,
            retryCount: model.retryCount,
            lastAttempt: model.lastAttempt,
            errorMessage: model.errorMessage,
            createdAt: model.createdAt
        )
    }

    static func toSwiftData(_ item: SyncQueueItem) -> SyncQueueSwiftDataModel {
        SyncQueueSwiftDataModel(
            id: item.id,
            runId: item.runId,
            statusRaw: item.status.rawValue,
            retryCount: item.retryCount,
            lastAttempt: item.lastAttempt,
            errorMessage: item.errorMessage,
            createdAt: item.createdAt
        )
    }
}
