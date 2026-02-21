import Foundation
import SwiftData
import os

final class LocalGroupChallengeRepository: GroupChallengeRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func fetchActiveChallenges() async throws -> [GroupChallenge] {
        let context = ModelContext(modelContainer)
        let active = "active"
        let descriptor = FetchDescriptor<GroupChallengeSwiftDataModel>(
            predicate: #Predicate { $0.statusRaw == active },
            sortBy: [SortDescriptor(\.endDate)]
        )
        let results = try context.fetch(descriptor)
        return results.compactMap { GroupChallengeSwiftDataMapper.toDomain($0) }
    }

    func fetchCompletedChallenges() async throws -> [GroupChallenge] {
        let context = ModelContext(modelContainer)
        let completed = "completed"
        let expired = "expired"
        let descriptor = FetchDescriptor<GroupChallengeSwiftDataModel>(
            predicate: #Predicate { $0.statusRaw == completed || $0.statusRaw == expired },
            sortBy: [SortDescriptor(\.endDate, order: .reverse)]
        )
        let results = try context.fetch(descriptor)
        return results.compactMap { GroupChallengeSwiftDataMapper.toDomain($0) }
    }

    func createChallenge(_ challenge: GroupChallenge) async throws -> GroupChallenge {
        let context = ModelContext(modelContainer)
        let model = GroupChallengeSwiftDataMapper.toSwiftData(challenge)
        context.insert(model)
        try context.save()
        Logger.social.info("Challenge created: \(challenge.name)")
        return challenge
    }

    func joinChallenge(_ challengeId: UUID) async throws {
        let context = ModelContext(modelContainer)
        let targetId = challengeId
        var descriptor = FetchDescriptor<GroupChallengeSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard try context.fetch(descriptor).first != nil else {
            throw DomainError.groupChallengeNotFound
        }

        Logger.social.info("Join challenge recorded locally: \(targetId)")
    }

    func leaveChallenge(_ challengeId: UUID) async throws {
        let context = ModelContext(modelContainer)
        let targetId = challengeId
        var descriptor = FetchDescriptor<GroupChallengeSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard try context.fetch(descriptor).first != nil else {
            throw DomainError.groupChallengeNotFound
        }

        Logger.social.info("Leave challenge recorded locally: \(targetId)")
    }

    func updateProgress(challengeId: UUID, value: Double) async throws {
        let context = ModelContext(modelContainer)
        let targetId = challengeId
        var descriptor = FetchDescriptor<GroupChallengeSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let model = try context.fetch(descriptor).first else {
            throw DomainError.groupChallengeNotFound
        }

        var participants = decodeParticipants(model.participantsData)
        if !participants.isEmpty {
            participants[0].currentValue = value
            model.participantsData = encodeParticipants(participants)
        }

        try context.save()
        Logger.social.info("Challenge progress updated: \(targetId) -> \(value)")
    }

    // MARK: - Participant Encoding

    private struct CodableParticipant: Codable {
        var id: String
        var displayName: String
        var photoData: Data?
        var currentValue: Double
        var joinedDate: Date
    }

    private func decodeParticipants(_ data: Data) -> [CodableParticipant] {
        (try? JSONDecoder().decode([CodableParticipant].self, from: data)) ?? []
    }

    private func encodeParticipants(_ participants: [CodableParticipant]) -> Data {
        (try? JSONEncoder().encode(participants)) ?? Data()
    }
}
