import Foundation
import SwiftData
import os

final class LocalActivityFeedRepository: ActivityFeedRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func fetchFeed(limit: Int) async throws -> [ActivityFeedItem] {
        let context = ModelContext(modelContainer)
        var descriptor = FetchDescriptor<ActivityFeedItemSwiftDataModel>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let results = try context.fetch(descriptor)
        return results.compactMap { ActivityFeedItemSwiftDataMapper.toDomain($0) }
    }

    func publishActivity(_ item: ActivityFeedItem) async throws {
        let context = ModelContext(modelContainer)
        let model = ActivityFeedItemSwiftDataMapper.toSwiftData(item)
        context.insert(model)
        try context.save()
        Logger.social.info("Activity published: \(item.title)")
    }

    func toggleLike(itemId: UUID) async throws {
        let context = ModelContext(modelContainer)
        let targetId = itemId
        var descriptor = FetchDescriptor<ActivityFeedItemSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let model = try context.fetch(descriptor).first else {
            throw DomainError.socialProfileNotFound
        }

        model.isLikedByMe.toggle()
        model.likeCount += model.isLikedByMe ? 1 : -1
        try context.save()
        Logger.social.info("Like toggled for activity: \(targetId)")
    }
}
