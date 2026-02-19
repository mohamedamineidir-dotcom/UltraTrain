import Foundation

enum StravaUploadQueueMapper {

    static func toDomain(_ model: StravaUploadQueueSwiftDataModel) -> StravaUploadQueueItem? {
        guard let status = StravaQueueItemStatus(rawValue: model.statusRaw) else { return nil }
        return StravaUploadQueueItem(
            id: model.id,
            runId: model.runId,
            status: status,
            retryCount: model.retryCount,
            lastAttempt: model.lastAttempt,
            stravaActivityId: model.stravaActivityId,
            errorMessage: model.errorMessage,
            createdAt: model.createdAt
        )
    }

    static func toSwiftData(_ item: StravaUploadQueueItem) -> StravaUploadQueueSwiftDataModel {
        StravaUploadQueueSwiftDataModel(
            id: item.id,
            runId: item.runId,
            statusRaw: item.status.rawValue,
            retryCount: item.retryCount,
            lastAttempt: item.lastAttempt,
            stravaActivityId: item.stravaActivityId,
            errorMessage: item.errorMessage,
            createdAt: item.createdAt
        )
    }
}
