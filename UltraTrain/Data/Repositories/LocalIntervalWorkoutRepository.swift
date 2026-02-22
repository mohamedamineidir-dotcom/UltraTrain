import Foundation
import SwiftData
import os

final class LocalIntervalWorkoutRepository: IntervalWorkoutRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getWorkouts() async throws -> [IntervalWorkout] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<IntervalWorkoutSwiftDataModel>(
            sortBy: [SortDescriptor(\.name)]
        )
        let results = try context.fetch(descriptor)
        return results.compactMap { IntervalWorkoutSwiftDataMapper.toDomain($0) }
    }

    func getWorkout(id: UUID) async throws -> IntervalWorkout? {
        let context = ModelContext(modelContainer)
        let targetId = id
        var descriptor = FetchDescriptor<IntervalWorkoutSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else { return nil }
        return IntervalWorkoutSwiftDataMapper.toDomain(model)
    }

    func saveWorkout(_ workout: IntervalWorkout) async throws {
        let context = ModelContext(modelContainer)
        let model = IntervalWorkoutSwiftDataMapper.toSwiftData(workout)
        context.insert(model)
        try context.save()
        Logger.workouts.info("Interval workout saved: \(workout.name)")
    }

    func deleteWorkout(id: UUID) async throws {
        let context = ModelContext(modelContainer)
        let targetId = id
        var descriptor = FetchDescriptor<IntervalWorkoutSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let model = try context.fetch(descriptor).first else {
            throw DomainError.intervalWorkoutNotFound
        }

        context.delete(model)
        try context.save()
        Logger.workouts.info("Interval workout deleted: \(targetId)")
    }
}
