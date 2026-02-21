import Foundation
import SwiftData
import os

final class LocalChallengeRepository: ChallengeRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getEnrollments() async throws -> [ChallengeEnrollment] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<ChallengeEnrollmentSwiftDataModel>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        let results = try context.fetch(descriptor)
        return results.compactMap { ChallengeEnrollmentSwiftDataMapper.toDomain($0) }
    }

    func getActiveEnrollments() async throws -> [ChallengeEnrollment] {
        let context = ModelContext(modelContainer)
        let activeRaw = ChallengeStatus.active.rawValue
        let descriptor = FetchDescriptor<ChallengeEnrollmentSwiftDataModel>(
            predicate: #Predicate { $0.statusRaw == activeRaw },
            sortBy: [SortDescriptor(\.startDate)]
        )
        let results = try context.fetch(descriptor)
        return results.compactMap { ChallengeEnrollmentSwiftDataMapper.toDomain($0) }
    }

    func saveEnrollment(_ enrollment: ChallengeEnrollment) async throws {
        let context = ModelContext(modelContainer)
        let model = ChallengeEnrollmentSwiftDataMapper.toSwiftData(enrollment)
        context.insert(model)
        try context.save()
        Logger.challenges.info("Challenge enrollment saved: \(enrollment.challengeDefinitionId)")
    }

    func updateEnrollment(_ enrollment: ChallengeEnrollment) async throws {
        let context = ModelContext(modelContainer)
        let targetId = enrollment.id
        var descriptor = FetchDescriptor<ChallengeEnrollmentSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let existing = try context.fetch(descriptor).first else {
            throw DomainError.challengeNotFound
        }

        existing.statusRaw = enrollment.status.rawValue
        existing.completedDate = enrollment.completedDate
        existing.updatedAt = Date()

        try context.save()
        Logger.challenges.info("Challenge enrollment updated: \(enrollment.challengeDefinitionId)")
    }

    func deleteEnrollment(id: UUID) async throws {
        let context = ModelContext(modelContainer)
        let targetId = id
        var descriptor = FetchDescriptor<ChallengeEnrollmentSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let model = try context.fetch(descriptor).first else {
            throw DomainError.challengeNotFound
        }

        context.delete(model)
        try context.save()
        Logger.challenges.info("Challenge enrollment deleted: \(targetId)")
    }
}
