import Foundation
@testable import UltraTrain

final class MockStravaImportService: StravaImportServiceProtocol, @unchecked Sendable {
    var shouldThrow = false
    var activities: [StravaActivity] = []
    var importedActivity: StravaActivity?
    var returnedRun: CompletedRun?

    func fetchActivities(page: Int, perPage: Int) async throws -> [StravaActivity] {
        if shouldThrow {
            throw DomainError.stravaImportFailed(reason: "Mock fetch error")
        }
        return activities
    }

    func importActivity(_ activity: StravaActivity, athleteId: UUID) async throws -> CompletedRun {
        if shouldThrow {
            throw DomainError.stravaImportFailed(reason: "Mock import error")
        }
        importedActivity = activity
        if let run = returnedRun {
            return run
        }
        return CompletedRun(
            id: UUID(),
            athleteId: athleteId,
            date: activity.startDate,
            distanceKm: activity.distanceKm,
            elevationGainM: activity.totalElevationGain,
            elevationLossM: 0,
            duration: Double(activity.movingTimeSeconds),
            averageHeartRate: activity.averageHeartRate.map { Int($0) },
            maxHeartRate: activity.maxHeartRate.map { Int($0) },
            averagePaceSecondsPerKm: activity.distanceKm > 0 ? Double(activity.movingTimeSeconds) / activity.distanceKm : 0,
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: "Imported from Strava: \(activity.name)",
            pausedDuration: 0,
            stravaActivityId: activity.id,
            isStravaImport: true
        )
    }
}
