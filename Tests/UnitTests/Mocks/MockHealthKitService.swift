import Foundation
@testable import UltraTrain

final class MockHealthKitService: HealthKitServiceProtocol, @unchecked Sendable {
    var authorizationStatus: HealthKitAuthStatus = .notDetermined
    var shouldThrow = false
    var requestAuthorizationCalled = false
    var startStreamCalled = false
    var stopStreamCalled = false
    var restingHR: Int?
    var maxHR: Int?
    var workouts: [HealthKitWorkout] = []
    var heartRateReadings: [HealthKitHeartRateReading] = []
    var bodyWeight: Double?
    var saveWorkoutCalled = false
    var savedRun: CompletedRun?

    func requestAuthorization() async throws {
        requestAuthorizationCalled = true
        if shouldThrow { throw DomainError.healthKitUnavailable }
        authorizationStatus = .authorized
    }

    func startHeartRateStream() -> AsyncStream<HealthKitHeartRateReading> {
        startStreamCalled = true
        return AsyncStream { continuation in
            for reading in self.heartRateReadings {
                continuation.yield(reading)
            }
            continuation.finish()
        }
    }

    func stopHeartRateStream() {
        stopStreamCalled = true
    }

    func fetchRestingHeartRate() async throws -> Int? {
        if shouldThrow { throw DomainError.healthKitUnavailable }
        return restingHR
    }

    func fetchMaxHeartRate() async throws -> Int? {
        if shouldThrow { throw DomainError.healthKitUnavailable }
        return maxHR
    }

    func fetchRunningWorkouts(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HealthKitWorkout] {
        if shouldThrow { throw DomainError.healthKitUnavailable }
        return workouts.filter { $0.startDate >= startDate && $0.startDate <= endDate }
    }

    func saveWorkout(run: CompletedRun) async throws {
        if shouldThrow { throw DomainError.healthKitWriteDenied }
        saveWorkoutCalled = true
        savedRun = run
    }

    func fetchBodyWeight() async throws -> Double? {
        if shouldThrow { throw DomainError.healthKitUnavailable }
        return bodyWeight
    }
}
