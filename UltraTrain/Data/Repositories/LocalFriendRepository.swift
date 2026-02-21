import Foundation
import SwiftData
import os

final class LocalFriendRepository: FriendRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func fetchFriends() async throws -> [FriendConnection] {
        let context = ModelContext(modelContainer)
        let accepted = "accepted"
        let descriptor = FetchDescriptor<FriendConnectionSwiftDataModel>(
            predicate: #Predicate { $0.statusRaw == accepted },
            sortBy: [SortDescriptor(\.friendDisplayName)]
        )
        let results = try context.fetch(descriptor)
        return results.compactMap { FriendConnectionSwiftDataMapper.toDomain($0) }
    }

    func fetchPendingRequests() async throws -> [FriendConnection] {
        let context = ModelContext(modelContainer)
        let pending = "pending"
        let descriptor = FetchDescriptor<FriendConnectionSwiftDataModel>(
            predicate: #Predicate { $0.statusRaw == pending },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        let results = try context.fetch(descriptor)
        return results.compactMap { FriendConnectionSwiftDataMapper.toDomain($0) }
    }

    func sendFriendRequest(toProfileId: String, displayName: String) async throws -> FriendConnection {
        let context = ModelContext(modelContainer)

        let connection = FriendConnection(
            id: UUID(),
            friendProfileId: toProfileId,
            friendDisplayName: displayName,
            friendPhotoData: nil,
            status: .pending,
            createdDate: Date(),
            acceptedDate: nil
        )

        let model = FriendConnectionSwiftDataMapper.toSwiftData(connection)
        context.insert(model)
        try context.save()
        Logger.social.info("Friend request sent to: \(displayName)")
        return connection
    }

    func acceptFriendRequest(_ connectionId: UUID) async throws {
        let context = ModelContext(modelContainer)
        let targetId = connectionId
        var descriptor = FetchDescriptor<FriendConnectionSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let existing = try context.fetch(descriptor).first else {
            throw DomainError.friendRequestFailed(reason: "Connection not found")
        }

        existing.statusRaw = FriendStatus.accepted.rawValue
        existing.acceptedDate = Date()
        try context.save()
        Logger.social.info("Friend request accepted: \(existing.friendDisplayName)")
    }

    func declineFriendRequest(_ connectionId: UUID) async throws {
        let context = ModelContext(modelContainer)
        let targetId = connectionId
        var descriptor = FetchDescriptor<FriendConnectionSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let existing = try context.fetch(descriptor).first else {
            throw DomainError.friendRequestFailed(reason: "Connection not found")
        }

        existing.statusRaw = FriendStatus.declined.rawValue
        try context.save()
        Logger.social.info("Friend request declined: \(existing.friendDisplayName)")
    }

    func removeFriend(_ connectionId: UUID) async throws {
        let context = ModelContext(modelContainer)
        let targetId = connectionId
        var descriptor = FetchDescriptor<FriendConnectionSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let model = try context.fetch(descriptor).first else {
            throw DomainError.friendRequestFailed(reason: "Connection not found")
        }

        context.delete(model)
        try context.save()
        Logger.social.info("Friend removed: \(model.friendDisplayName)")
    }
}
