import Foundation
import SwiftData
import os

final class LocalRecoveryRepository: RecoveryRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getSnapshots(from startDate: Date, to endDate: Date) async throws -> [RecoverySnapshot] {
        let context = ModelContext(modelContainer)
        let start = startDate
        let end = endDate
        let descriptor = FetchDescriptor<RecoverySnapshotSwiftDataModel>(
            predicate: #Predicate { $0.date >= start && $0.date <= end },
            sortBy: [SortDescriptor(\.date)]
        )
        let results = try context.fetch(descriptor)
        return results.map { RecoverySnapshotSwiftDataMapper.toDomain($0) }
    }

    func getLatestSnapshot() async throws -> RecoverySnapshot? {
        let context = ModelContext(modelContainer)
        var descriptor = FetchDescriptor<RecoverySnapshotSwiftDataModel>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else { return nil }
        return RecoverySnapshotSwiftDataMapper.toDomain(model)
    }

    func saveSnapshot(_ snapshot: RecoverySnapshot) async throws {
        let context = ModelContext(modelContainer)
        let model = RecoverySnapshotSwiftDataMapper.toSwiftData(snapshot)
        context.insert(model)
        try context.save()
        Logger.recovery.info("Recovery snapshot saved: score=\(snapshot.recoveryScore.overallScore)")
    }
}
