import Foundation
import os

// @unchecked Sendable: immutable after init
final class StravaUploadQueueService: StravaUploadQueueServiceProtocol, @unchecked Sendable {

    private let queueRepository: any StravaUploadQueueRepository
    private let runRepository: any RunRepository
    private let uploadService: any StravaUploadServiceProtocol

    init(
        queueRepository: any StravaUploadQueueRepository,
        runRepository: any RunRepository,
        uploadService: any StravaUploadServiceProtocol
    ) {
        self.queueRepository = queueRepository
        self.runRepository = runRepository
        self.uploadService = uploadService
    }

    func enqueueUpload(runId: UUID) async throws {
        if let existing = try await queueRepository.getItem(forRunId: runId) {
            guard existing.status == .failed else { return }
            var updated = existing
            updated.status = .pending
            updated.retryCount = 0
            updated.errorMessage = nil
            try await queueRepository.updateItem(updated)
            Logger.strava.info("Reset failed queue item for run \(runId)")
            return
        }

        let item = StravaUploadQueueItem(
            id: UUID(),
            runId: runId,
            status: .pending,
            retryCount: 0,
            lastAttempt: nil,
            stravaActivityId: nil,
            errorMessage: nil,
            createdAt: .now
        )
        try await queueRepository.saveItem(item)
        Logger.strava.info("Enqueued upload for run \(runId)")
    }

    func processQueue() async {
        do {
            let items = try await queueRepository.getPendingItems()
            for item in items {
                guard !item.hasReachedMaxRetries else {
                    Logger.strava.warning("Skipping run \(item.runId) — max retries reached")
                    continue
                }
                if let lastAttempt = item.lastAttempt {
                    let elapsed = Date.now.timeIntervalSince(lastAttempt)
                    guard elapsed >= item.nextRetryDelay else { continue }
                }
                await processItem(item)
            }
        } catch {
            Logger.strava.error("Failed to fetch queue items: \(error)")
        }
    }

    func getQueueStatus(forRunId runId: UUID) async -> StravaQueueItemStatus? {
        do {
            return try await queueRepository.getItem(forRunId: runId)?.status
        } catch {
            Logger.strava.warning("Failed to get queue status for run \(runId): \(error)")
            return nil
        }
    }

    func getPendingCount() async -> Int {
        do {
            return try await queueRepository.getPendingCount()
        } catch {
            Logger.strava.warning("Failed to get pending count: \(error)")
            return 0
        }
    }

    // MARK: - Private

    private func processItem(_ item: StravaUploadQueueItem) async {
        var mutableItem = item
        mutableItem.status = .uploading
        do {
            try await queueRepository.updateItem(mutableItem)
        } catch {
            Logger.strava.warning("Failed to mark item as uploading for run \(item.runId): \(error)")
        }

        do {
            guard let run = try await runRepository.getRun(id: item.runId) else {
                Logger.strava.warning("Run \(item.runId) not found — removing from queue")
                do {
                    try await queueRepository.deleteItem(id: item.id)
                } catch {
                    Logger.strava.warning("Failed to remove orphaned queue item \(item.id): \(error)")
                }
                return
            }

            let activityId = try await uploadService.uploadRun(run)

            mutableItem.status = .completed
            mutableItem.stravaActivityId = activityId
            mutableItem.lastAttempt = .now
            do {
                try await queueRepository.updateItem(mutableItem)
            } catch {
                Logger.strava.warning("Failed to mark upload as completed for run \(item.runId): \(error)")
            }

            var updatedRun = run
            updatedRun.stravaActivityId = activityId
            try await runRepository.updateRun(updatedRun)

            Logger.strava.info("Upload completed for run \(item.runId) — activity \(activityId)")
        } catch {
            mutableItem.status = .failed
            mutableItem.retryCount += 1
            mutableItem.lastAttempt = .now
            mutableItem.errorMessage = error.localizedDescription
            do {
                try await queueRepository.updateItem(mutableItem)
            } catch let updateError {
                Logger.strava.warning("Failed to update queue item after error for run \(item.runId): \(updateError)")
            }
            Logger.strava.error("Upload failed for run \(item.runId) (attempt \(mutableItem.retryCount)): \(error)")
        }
    }
}
