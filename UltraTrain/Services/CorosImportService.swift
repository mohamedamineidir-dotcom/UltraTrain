import Foundation
import os

protocol CorosImportServiceProtocol: Sendable {
    func fetchRecentActivities(limit: Int) async throws -> [CompletedRun]
}

final class CorosImportService: CorosImportServiceProtocol, @unchecked Sendable {
    private let authService: CorosAuthServiceProtocol
    private let logger = Logger(subsystem: "com.ultratrain", category: "coros-import")
    private let baseURL = "https://open.coros.com/v2"

    init(authService: CorosAuthServiceProtocol) {
        self.authService = authService
    }

    func fetchRecentActivities(limit: Int = 20) async throws -> [CompletedRun] {
        let token = try await authService.getValidToken()

        var request = URLRequest(url: URL(string: "\(baseURL)/coros/sport/list?size=\(limit)")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            logger.error("Coros API returned non-200 status")
            throw CorosError.notAuthenticated
        }

        let wrapper = try JSONDecoder().decode(CorosActivityResponse.self, from: data)
        return wrapper.data.compactMap { mapToCompletedRun($0) }
    }

    private func mapToCompletedRun(_ activity: CorosActivity) -> CompletedRun? {
        guard activity.sportType == 100 || activity.sportType == 102 else {
            return nil // 100 = running, 102 = trail running
        }

        let distanceKm = activity.distance / 1000.0
        let duration = TimeInterval(activity.duration)
        let pace = distanceKm > 0 ? duration / distanceKm : 0

        return CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: Date(timeIntervalSince1970: TimeInterval(activity.startTime)),
            distanceKm: distanceKm,
            elevationGainM: activity.totalUp ?? 0,
            elevationLossM: activity.totalDown ?? 0,
            duration: duration,
            averageHeartRate: activity.avgHr,
            maxHeartRate: nil,
            averagePaceSecondsPerKm: pace,
            gpsTrack: [],
            splits: [],
            notes: activity.name,
            pausedDuration: 0,
            importSource: .coros
        )
    }
}

// MARK: - Coros API DTOs

struct CorosActivityResponse: Decodable {
    let data: [CorosActivity]
}

struct CorosActivity: Decodable {
    let sportType: Int
    let name: String?
    let startTime: Int
    let duration: Int
    let distance: Double
    let totalUp: Double?
    let totalDown: Double?
    let avgHr: Int?
}
