import Foundation

enum HealthKitAuthStatus: Sendable, Equatable {
    case notDetermined
    case authorized
    case denied
    case unavailable
}

struct HealthKitHeartRateReading: Sendable {
    let beatsPerMinute: Int
    let timestamp: Date
}

struct HealthKitWorkout: Identifiable, Sendable, Equatable {
    let id: UUID
    let originalUUID: String
    let startDate: Date
    let endDate: Date
    let distanceKm: Double
    let elevationGainM: Double
    let duration: TimeInterval
    let averageHeartRate: Int?
    let maxHeartRate: Int?
    let source: String
    let activityType: ActivityType
}

protocol HealthKitServiceProtocol: AnyObject, Sendable {
    var authorizationStatus: HealthKitAuthStatus { get }
    func requestAuthorization() async throws
    func startHeartRateStream() -> AsyncStream<HealthKitHeartRateReading>
    func stopHeartRateStream()
    func fetchRestingHeartRate() async throws -> Int?
    func fetchMaxHeartRate() async throws -> Int?
    func fetchRunningWorkouts(from startDate: Date, to endDate: Date) async throws -> [HealthKitWorkout]
    func fetchWorkouts(activityTypes: [ActivityType], from startDate: Date, to endDate: Date) async throws -> [HealthKitWorkout]
    func saveWorkout(run: CompletedRun) async throws
    func fetchBodyWeight() async throws -> Double?
    func fetchSleepData(from startDate: Date, to endDate: Date) async throws -> [SleepEntry]
    func fetchHRVData(from startDate: Date, to endDate: Date) async throws -> [HRVReading]
}
