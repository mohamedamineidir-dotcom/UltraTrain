import Foundation

enum IntervalWorkoutSwiftDataMapper {

    // MARK: - Domain -> SwiftData

    static func toSwiftData(_ workout: IntervalWorkout) -> IntervalWorkoutSwiftDataModel {
        let phasesData = encodePhases(workout.phases)
        return IntervalWorkoutSwiftDataModel(
            id: workout.id,
            name: workout.name,
            descriptionText: workout.descriptionText,
            phasesData: phasesData,
            categoryRaw: workout.category.rawValue,
            estimatedDurationSeconds: workout.estimatedDurationSeconds,
            estimatedDistanceKm: workout.estimatedDistanceKm,
            isUserCreated: workout.isUserCreated
        )
    }

    // MARK: - SwiftData -> Domain

    static func toDomain(_ model: IntervalWorkoutSwiftDataModel) -> IntervalWorkout? {
        guard let category = WorkoutCategory(rawValue: model.categoryRaw) else { return nil }
        let phases = decodePhases(model.phasesData)

        return IntervalWorkout(
            id: model.id,
            name: model.name,
            descriptionText: model.descriptionText,
            phases: phases,
            category: category,
            estimatedDurationSeconds: model.estimatedDurationSeconds,
            estimatedDistanceKm: model.estimatedDistanceKm,
            isUserCreated: model.isUserCreated
        )
    }

    // MARK: - Phase JSON

    private static func encodePhases(_ phases: [IntervalPhase]) -> Data {
        (try? JSONEncoder().encode(phases)) ?? Data()
    }

    private static func decodePhases(_ data: Data) -> [IntervalPhase] {
        guard !data.isEmpty else { return [] }
        return (try? JSONDecoder().decode([IntervalPhase].self, from: data)) ?? []
    }
}
