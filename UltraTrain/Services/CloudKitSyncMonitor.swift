import Foundation
import SwiftData
import os

@Observable
final class CloudKitSyncMonitor: @unchecked Sendable {
    var lastSyncDate: Date?
    var syncError: String?

    private var observationTask: Task<Void, Never>?

    func startMonitoring(modelContainer: ModelContainer) {
        observationTask = Task { @MainActor [weak self] in
            let notifications = NotificationCenter.default.notifications(
                named: .NSPersistentStoreRemoteChange,
                object: modelContainer
            )
            for await _ in notifications {
                self?.lastSyncDate = Date()
                self?.syncError = nil
                Logger.cloudKit.info("Received remote change notification from CloudKit")
            }
        }
        Logger.cloudKit.info("CloudKit sync monitoring started")
    }

    func stopMonitoring() {
        observationTask?.cancel()
        observationTask = nil
        Logger.cloudKit.info("CloudKit sync monitoring stopped")
    }

    deinit {
        observationTask?.cancel()
    }
}
