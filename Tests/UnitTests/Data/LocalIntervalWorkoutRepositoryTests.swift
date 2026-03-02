import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalIntervalWorkoutRepository Tests")
@MainActor
struct LocalIntervalWorkoutRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([IntervalWorkoutSwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeWorkout(
        id: UUID = UUID(),
        name: String = "Hill Repeats",
        category: WorkoutCategory = .hillTraining
    ) -> IntervalWorkout {
        IntervalWorkout(
            id: id,
            name: name,
            descriptionText: "4x3min uphill at threshold",
            phases: [
                IntervalPhase(
                    id: UUID(),
                    phaseType: .warmUp,
                    trigger: .duration(seconds: 600),
                    targetIntensity: .easy,
                    repeatCount: 1
                ),
                IntervalPhase(
                    id: UUID(),
                    phaseType: .work,
                    trigger: .duration(seconds: 180),
                    targetIntensity: .hard,
                    repeatCount: 4
                )
            ],
            category: category,
            estimatedDurationSeconds: 2400,
            estimatedDistanceKm: 6.0,
            isUserCreated: true
        )
    }

    @Test("Save and get workouts")
    func saveAndGetWorkouts() async throws {
        let container = try makeContainer()
        let repo = LocalIntervalWorkoutRepository(modelContainer: container)

        try await repo.saveWorkout(makeWorkout(name: "Speed Intervals"))

        let results = try await repo.getWorkouts()
        #expect(results.count == 1)
        #expect(results.first?.name == "Speed Intervals")
    }

    @Test("Get workout by ID returns matching workout")
    func getWorkoutByIdReturnsMatching() async throws {
        let container = try makeContainer()
        let repo = LocalIntervalWorkoutRepository(modelContainer: container)
        let workoutId = UUID()

        try await repo.saveWorkout(makeWorkout(id: workoutId, name: "Fartlek"))

        let fetched = try await repo.getWorkout(id: workoutId)
        #expect(fetched != nil)
        #expect(fetched?.name == "Fartlek")
    }

    @Test("Get workout by ID returns nil for unknown")
    func getWorkoutByIdReturnsNilForUnknown() async throws {
        let container = try makeContainer()
        let repo = LocalIntervalWorkoutRepository(modelContainer: container)

        let fetched = try await repo.getWorkout(id: UUID())
        #expect(fetched == nil)
    }

    @Test("Delete workout removes it")
    func deleteWorkoutRemovesIt() async throws {
        let container = try makeContainer()
        let repo = LocalIntervalWorkoutRepository(modelContainer: container)
        let workoutId = UUID()

        try await repo.saveWorkout(makeWorkout(id: workoutId))
        try await repo.deleteWorkout(id: workoutId)

        let results = try await repo.getWorkouts()
        #expect(results.isEmpty)
    }

    @Test("Delete workout throws when not found")
    func deleteWorkoutThrowsWhenNotFound() async throws {
        let container = try makeContainer()
        let repo = LocalIntervalWorkoutRepository(modelContainer: container)

        await #expect(throws: DomainError.self) {
            try await repo.deleteWorkout(id: UUID())
        }
    }

    @Test("Workouts returned sorted by name")
    func workoutsReturnedSortedByName() async throws {
        let container = try makeContainer()
        let repo = LocalIntervalWorkoutRepository(modelContainer: container)

        try await repo.saveWorkout(makeWorkout(name: "Zephyr Intervals"))
        try await repo.saveWorkout(makeWorkout(name: "Alpine Repeats"))

        let results = try await repo.getWorkouts()
        #expect(results.count == 2)
        #expect(results[0].name == "Alpine Repeats")
        #expect(results[1].name == "Zephyr Intervals")
    }
}
