import Foundation
import os

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
        try? await queueRepository.getItem(forRunId: runId)?.status
    }

    func getPendingCount() async -> Int {
        (try? await queueRepository.getPendingCount()) ?? 0
    }

    // MARK: - Private

    private func processItem(_ item: StravaUploadQueueItem) async {
        var mutableItem = item
        mutableItem.status = .uploading
        try? await queueRepository.updateItem(mutableItem)

        do {
            guard let run = try await runRepository.getRun(id: item.runId) else {
                Logger.strava.warning("Run \(item.runId) not found — removing from queue")
                try? await queueRepository.deleteItem(id: item.id)
                return
            }

            let activityId = try await uploadService.uploadRun(run)

            mutableItem.status = .completed
            mutableItem.stravaActivityId = activityId
            mutableItem.lastAttempt = .now
            try? await queueRepository.updateItem(mutableItem)

            var updatedRun = run
            updatedRun.stravaActivityId = activityId
            try await runRepository.updateRun(updatedRun)

            Logger.strava.info("Upload completed for run \(item.runId) — activity \(activityId)")
        } catch {
            mutableItem.status = .failed
            mutableItem.retryCount += 1
            mutableItem.lastAttempt = .now
            mutableItem.errorMessage = error.localizedDescription
            try? await queueRepository.updateItem(mutableItem)
            Logger.strava.error("Upload failed for run \(item.runId) (attempt \(mutableItem.retryCount)): \(error)")
        }
    }
}
