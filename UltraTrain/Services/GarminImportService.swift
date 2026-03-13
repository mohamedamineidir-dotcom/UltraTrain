import Foundation
import os

protocol GarminImportServiceProtocol: Sendable {
    func fetchRecentActivities(limit: Int) async throws -> [CompletedRun]
}

final class GarminImportService: GarminImportServiceProtocol, @unchecked Sendable {
    private let authService: GarminAuthServiceProtocol
    private let logger = Logger(subsystem: "com.ultratrain", category: "garmin-import")
    private let baseURL = "https://apis.garmin.com/wellness-api/rest"

    init(authService: GarminAuthServiceProtocol) {
        self.authService = authService
    }

    func fetchRecentActivities(limit: Int = 20) async throws -> [CompletedRun] {
        let token = try await authService.getValidToken()

        var request = URLRequest(url: URL(string: "\(baseURL)/activities?limit=\(limit)")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            logger.error("Garmin API returned non-200 status")
            throw GarminError.notAuthenticated
        }

        let activities = try JSONDecoder().decode([GarminActivity].self, from: data)
        return activities.compactMap { mapToCompletedRun($0) }
    }

    private func mapToCompletedRun(_ activity: GarminActivity) -> CompletedRun? {
        guard activity.activityType == "running" || activity.activityType == "trail_running" else {
            return nil
        }

        let distanceKm = activity.distanceInMeters / 1000.0
        let duration = TimeInterval(activity.durationInSeconds)
        let pace = distanceKm > 0 ? duration / distanceKm : 0

        return CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: Date(timeIntervalSince1970: TimeInterval(activity.startTimeInSeconds)),
            distanceKm: distanceKm,
            elevationGainM: activity.elevationGainInMeters ?? 0,
            elevationLossM: activity.elevationLossInMeters ?? 0,
            duration: duration,
            averageHeartRate: activity.averageHeartRateInBeatsPerMinute,
            maxHeartRate: activity.maxHeartRateInBeatsPerMinute,
            averagePaceSecondsPerKm: pace,
            gpsTrack: [],
            splits: [],
            notes: activity.activityName,
            pausedDuration: 0,
            importSource: .garminConnect
        )
    }
}

// MARK: - Garmin API DTOs

struct GarminActivity: Decodable {
    let activityId: Int
    let activityName: String?
    let activityType: String
    let startTimeInSeconds: Int
    let durationInSeconds: Int
    let distanceInMeters: Double
    let elevationGainInMeters: Double?
    let elevationLossInMeters: Double?
    let averageHeartRateInBeatsPerMinute: Int?
    let maxHeartRateInBeatsPerMinute: Int?
}
