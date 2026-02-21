import Foundation
import CloudKit
import os

actor CloudKitAccountManager {

    private let container: CKContainer
    private var cachedUserRecordName: String?

    init(container: CKContainer = .default()) {
        self.container = container
    }

    var publicDatabase: CKDatabase {
        container.publicCloudDatabase
    }

    func ensureAccountAvailable() async throws {
        let status = try await container.accountStatus()
        guard status == .available else {
            Logger.cloudKit.error("iCloud account not available: \(String(describing: status))")
            throw DomainError.iCloudAccountUnavailable
        }
    }

    func fetchMyRecordName() async throws -> String {
        if let cached = cachedUserRecordName {
            return cached
        }
        try await ensureAccountAvailable()
        let recordID = try await container.userRecordID()
        let name = recordID.recordName
        cachedUserRecordName = name
        Logger.cloudKit.info("Fetched user record name")
        return name
    }

    func clearCache() {
        cachedUserRecordName = nil
    }
}
