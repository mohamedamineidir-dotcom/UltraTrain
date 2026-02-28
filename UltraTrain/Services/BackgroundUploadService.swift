import Foundation
import os

protocol BackgroundUploadServiceProtocol: Sendable {
    func uploadRun(dto: RunUploadRequestDTO, syncItemId: UUID) async throws
    func handleSessionCompletion(identifier: String, completion: @escaping () -> Void)
}

final class BackgroundUploadService: NSObject, BackgroundUploadServiceProtocol, @unchecked Sendable {
    static let sessionIdentifier = "com.ultratrain.app.background-upload"
    static let gpsThreshold = 500

    private let baseURL: URL
    private let syncQueueRepository: any SyncQueueRepository
    private let authService: any AuthServiceProtocol
    private let fileManager: BackgroundUploadFileManager

    private lazy var backgroundSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: Self.sessionIdentifier)
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        config.timeoutIntervalForResource = 600
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private var pendingCompletionHandler: (() -> Void)?
    private var taskToSyncItemId: [Int: UUID] = [:]
    private let lock = NSLock()

    init(
        baseURL: URL = AppConfiguration.API.baseURL,
        syncQueueRepository: any SyncQueueRepository,
        authService: any AuthServiceProtocol,
        fileManager: BackgroundUploadFileManager = BackgroundUploadFileManager()
    ) {
        self.baseURL = baseURL
        self.syncQueueRepository = syncQueueRepository
        self.authService = authService
        self.fileManager = fileManager
        super.init()
        _ = backgroundSession
    }

    func uploadRun(dto: RunUploadRequestDTO, syncItemId: UUID) async throws {
        let fileURL = try fileManager.writeUploadFile(dto: dto, id: syncItemId)

        let token = try await authService.getValidAccessToken()

        var request = URLRequest(url: baseURL.appendingPathComponent("/runs"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(AppConfiguration.appVersion, forHTTPHeaderField: "X-Client-Version")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Idempotency-Key")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let task = backgroundSession.uploadTask(with: request, fromFile: fileURL)
        storeSyncItemId(syncItemId, for: task.taskIdentifier)

        Logger.backgroundUpload.info("Starting background upload for sync item \(syncItemId)")
        task.resume()
    }

    private nonisolated func storeSyncItemId(_ syncItemId: UUID, for taskIdentifier: Int) {
        lock.lock()
        taskToSyncItemId[taskIdentifier] = syncItemId
        lock.unlock()
    }

    func handleSessionCompletion(identifier: String, completion: @escaping () -> Void) {
        guard identifier == Self.sessionIdentifier else {
            completion()
            return
        }
        lock.lock()
        pendingCompletionHandler = completion
        lock.unlock()
    }
}

// MARK: - URLSessionDelegate

extension BackgroundUploadService: URLSessionDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        lock.lock()
        let handler = pendingCompletionHandler
        pendingCompletionHandler = nil
        lock.unlock()

        DispatchQueue.main.async {
            handler?()
        }
        Logger.backgroundUpload.info("Background session finished all events")
    }
}

// MARK: - URLSessionTaskDelegate

extension BackgroundUploadService: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lock.lock()
        let syncItemId = taskToSyncItemId.removeValue(forKey: task.taskIdentifier)
        lock.unlock()

        guard let syncItemId else { return }

        let statusCode = (task.response as? HTTPURLResponse)?.statusCode ?? 0

        Task {
            if let error {
                Logger.backgroundUpload.warning("Background upload failed for \(syncItemId): \(error)")
                await markItem(syncItemId, failed: true, message: error.localizedDescription)
            } else if (200...299).contains(statusCode) {
                Logger.backgroundUpload.info("Background upload succeeded for \(syncItemId)")
                await markItem(syncItemId, failed: false, message: nil)
            } else {
                Logger.backgroundUpload.warning("Background upload got status \(statusCode) for \(syncItemId)")
                await markItem(syncItemId, failed: true, message: "HTTP \(statusCode)")
            }

            fileManager.cleanupFile(for: syncItemId)
        }
    }

    private func markItem(_ syncItemId: UUID, failed: Bool, message: String?) async {
        do {
            let items = try await syncQueueRepository.getPendingItems()
            let failedItems = try await syncQueueRepository.getFailedItems()
            let allItems = items + failedItems
            guard var item = allItems.first(where: { $0.id == syncItemId }) else { return }

            if failed {
                item.retryCount += 1
                item.errorMessage = message
                item.status = item.hasReachedMaxRetries ? .failed : .pending
            } else {
                item.status = .completed
            }
            try await syncQueueRepository.updateItem(item)
        } catch {
            Logger.backgroundUpload.error("Failed to update sync queue item \(syncItemId): \(error)")
        }
    }
}
