import Foundation

protocol IntervalWorkoutRepository: Sendable {
    func getWorkouts() async throws -> [IntervalWorkout]
    func getWorkout(id: UUID) async throws -> IntervalWorkout?
    func saveWorkout(_ workout: IntervalWorkout) async throws
    func deleteWorkout(id: UUID) async throws
}
