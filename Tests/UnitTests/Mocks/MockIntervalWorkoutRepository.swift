import Foundation
@testable import UltraTrain

final class MockIntervalWorkoutRepository: IntervalWorkoutRepository, @unchecked Sendable {
    var workouts: [IntervalWorkout] = []
    var getWorkoutsCallCount = 0
    var getWorkoutCallCount = 0
    var saveCallCount = 0
    var deleteCallCount = 0
    var shouldThrow = false
    var lastSavedWorkout: IntervalWorkout?
    var lastDeletedId: UUID?

    func getWorkouts() async throws -> [IntervalWorkout] {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        getWorkoutsCallCount += 1
        return workouts
    }

    func getWorkout(id: UUID) async throws -> IntervalWorkout? {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        getWorkoutCallCount += 1
        return workouts.first { $0.id == id }
    }

    func saveWorkout(_ workout: IntervalWorkout) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        saveCallCount += 1
        lastSavedWorkout = workout
        workouts.append(workout)
    }

    func deleteWorkout(id: UUID) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        deleteCallCount += 1
        lastDeletedId = id
        workouts.removeAll { $0.id == id }
    }
}
