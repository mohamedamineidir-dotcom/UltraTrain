import Foundation
import SwiftData
import os

final class LocalFinishEstimateRepository: FinishEstimateRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getEstimate(for raceId: UUID) async throws -> FinishEstimate? {
        let context = ModelContext(modelContainer)
        let targetRaceId = raceId
        var descriptor = FetchDescriptor<FinishEstimateSwiftDataModel>(
            predicate: #Predicate { $0.raceId == targetRaceId },
            sortBy: [SortDescriptor(\.calculatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else { return nil }
        return FinishEstimateSwiftDataMapper.toDomain(model)
    }

    func saveEstimate(_ estimate: FinishEstimate) async throws {
        let context = ModelContext(modelContainer)
        let targetRaceId = estimate.raceId
        let descriptor = FetchDescriptor<FinishEstimateSwiftDataModel>(
            predicate: #Predicate { $0.raceId == targetRaceId }
        )
        let existing = try context.fetch(descriptor)
        for old in existing {
            context.delete(old)
        }
        let model = FinishEstimateSwiftDataMapper.toSwiftData(estimate)
        context.insert(model)
        try context.save()
        Logger.training.info("Finish estimate saved for race \(estimate.raceId)")
    }
}
