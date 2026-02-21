import Foundation
import SwiftData
import os

final class LocalSharedRunRepository: SharedRunRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func fetchSharedRuns() async throws -> [SharedRun] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<SharedRunSwiftDataModel>(
            sortBy: [SortDescriptor(\.sharedAt, order: .reverse)]
        )
        let results = try context.fetch(descriptor)
        return results.map { SharedRunSwiftDataMapper.toDomain($0) }
    }

    func shareRun(_ run: SharedRun, withFriendIds: [String]) async throws {
        let context = ModelContext(modelContainer)
        let model = SharedRunSwiftDataMapper.toSwiftData(run)
        context.insert(model)
        try context.save()
        Logger.social.info("Run shared with \(withFriendIds.count) friend(s)")
    }

    func revokeShare(_ runId: UUID) async throws {
        let context = ModelContext(modelContainer)
        let targetId = runId
        var descriptor = FetchDescriptor<SharedRunSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let model = try context.fetch(descriptor).first else {
            throw DomainError.sharingFailed(reason: "Shared run not found")
        }

        context.delete(model)
        try context.save()
        Logger.social.info("Run share revoked: \(targetId)")
    }

    func fetchRunsSharedByMe() async throws -> [SharedRun] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<SharedRunSwiftDataModel>(
            sortBy: [SortDescriptor(\.sharedAt, order: .reverse)]
        )
        let results = try context.fetch(descriptor)
        return results.map { SharedRunSwiftDataMapper.toDomain($0) }
    }
}
