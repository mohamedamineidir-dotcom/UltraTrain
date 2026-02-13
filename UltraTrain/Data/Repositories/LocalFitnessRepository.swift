import Foundation
import SwiftData
import os

final class LocalFitnessRepository: FitnessRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getSnapshots(from startDate: Date, to endDate: Date) async throws -> [FitnessSnapshot] {
        let context = ModelContext(modelContainer)
        let start = startDate
        let end = endDate
        let descriptor = FetchDescriptor<FitnessSnapshotSwiftDataModel>(
            predicate: #Predicate { $0.date >= start && $0.date <= end },
            sortBy: [SortDescriptor(\.date)]
        )
        let results = try context.fetch(descriptor)
        return results.map { FitnessSnapshotSwiftDataMapper.toDomain($0) }
    }

    func getLatestSnapshot() async throws -> FitnessSnapshot? {
        let context = ModelContext(modelContainer)
        var descriptor = FetchDescriptor<FitnessSnapshotSwiftDataModel>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else { return nil }
        return FitnessSnapshotSwiftDataMapper.toDomain(model)
    }

    func saveSnapshot(_ snapshot: FitnessSnapshot) async throws {
        let context = ModelContext(modelContainer)
        let model = FitnessSnapshotSwiftDataMapper.toSwiftData(snapshot)
        context.insert(model)
        try context.save()
        Logger.fitness.info("Fitness snapshot saved: CTL=\(snapshot.fitness, format: .fixed(precision: 1))")
    }
}
