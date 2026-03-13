import Foundation
import os

protocol SuuntoImportServiceProtocol: Sendable {
    func fetchRecentActivities(limit: Int) async throws -> [CompletedRun]
}

final class SuuntoImportService: SuuntoImportServiceProtocol, @unchecked Sendable {
    private let authService: SuuntoAuthServiceProtocol
    private let logger = Logger(subsystem: "com.ultratrain", category: "suunto-import")
    private let baseURL = "https://cloudapi.suunto.com/v2"

    init(authService: SuuntoAuthServiceProtocol) {
        self.authService = authService
    }

    func fetchRecentActivities(limit: Int = 20) async throws -> [CompletedRun] {
        let token = try await authService.getValidToken()

        var request = URLRequest(url: URL(string: "\(baseURL)/workouts?limit=\(limit)")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            logger.error("Suunto API returned non-200 status")
            throw SuuntoError.notAuthenticated
        }

        let wrapper = try JSONDecoder().decode(SuuntoWorkoutResponse.self, from: data)
        return wrapper.payload.compactMap { mapToCompletedRun($0) }
    }

    private func mapToCompletedRun(_ workout: SuuntoWorkout) -> CompletedRun? {
        guard workout.activityId == 1 || workout.activityId == 27 else {
            return nil // 1 = running, 27 = trail running
        }

        let distanceKm = workout.totalDistance / 1000.0
        let duration = workout.totalTime
        let pace = distanceKm > 0 ? duration / distanceKm : 0

        return CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: ISO8601DateFormatter().date(from: workout.startTime) ?? Date(),
            distanceKm: distanceKm,
            elevationGainM: workout.totalAscent ?? 0,
            elevationLossM: workout.totalDescent ?? 0,
            duration: duration,
            averageHeartRate: workout.avgHr,
            maxHeartRate: workout.maxHr,
            averagePaceSecondsPerKm: pace,
            gpsTrack: [],
            splits: [],
            notes: workout.workoutName,
            pausedDuration: 0,
            importSource: .suunto
        )
    }
}

// MARK: - Suunto API DTOs

struct SuuntoWorkoutResponse: Decodable {
    let payload: [SuuntoWorkout]
}

struct SuuntoWorkout: Decodable {
    let workoutKey: String
    let workoutName: String?
    let activityId: Int
    let startTime: String
    let totalTime: TimeInterval
    let totalDistance: Double
    let totalAscent: Double?
    let totalDescent: Double?
    let avgHr: Int?
    let maxHr: Int?
}
