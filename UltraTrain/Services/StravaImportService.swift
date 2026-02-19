import Foundation
import os

final class StravaImportService: StravaImportServiceProtocol {

    private let authService: any StravaAuthServiceProtocol
    private let runRepository: any RunRepository
    private let session: URLSession

    init(
        authService: any StravaAuthServiceProtocol,
        runRepository: any RunRepository,
        session: URLSession = .shared
    ) {
        self.authService = authService
        self.runRepository = runRepository
        self.session = session
    }

    // MARK: - Fetch Activities

    func fetchActivities(page: Int, perPage: Int) async throws -> [StravaActivity] {
        let token = try await authService.getValidToken()
        let url = URL(string: "\(AppConfiguration.Strava.apiBaseURL)/athlete/activities")!

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DomainError.stravaImportFailed(reason: "Failed to fetch activities")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dtos = try decoder.decode([StravaActivityDTO].self, from: data)

        let existingRuns = try await runRepository.getRecentRuns(limit: 200)

        return dtos.compactMap { dto -> StravaActivity? in
            guard dto.type == "Run" || dto.type == "TrailRun" else { return nil }
            let isImported = isDuplicate(dto: dto, existingRuns: existingRuns)
            return StravaActivity(
                id: dto.id,
                name: dto.name,
                type: dto.type,
                startDate: dto.startDate,
                distanceMeters: dto.distance,
                movingTimeSeconds: dto.movingTime,
                totalElevationGain: dto.totalElevationGain,
                averageHeartRate: dto.averageHeartrate,
                maxHeartRate: dto.maxHeartrate,
                isImported: isImported
            )
        }
    }

    // MARK: - Import Activity

    func importActivity(_ activity: StravaActivity, athleteId: UUID) async throws -> CompletedRun {
        let token = try await authService.getValidToken()
        let trackPoints = try await fetchStreams(activityId: activity.id, token: token)

        let splits = RunStatisticsCalculator.buildSplits(from: trackPoints)
        let distanceKm = RunStatisticsCalculator.totalDistanceKm(trackPoints)
        let elevation = ElevationCalculator.elevationChanges(trackPoints)
        let heartRates = trackPoints.compactMap(\.heartRate)
        let avgHR = heartRates.isEmpty ? nil : heartRates.reduce(0, +) / heartRates.count
        let maxHR = heartRates.max()
        let pace = RunStatisticsCalculator.averagePace(
            distanceKm: distanceKm > 0 ? distanceKm : activity.distanceKm,
            duration: Double(activity.movingTimeSeconds)
        )

        let run = CompletedRun(
            id: UUID(),
            athleteId: athleteId,
            date: activity.startDate,
            distanceKm: distanceKm > 0 ? distanceKm : activity.distanceKm,
            elevationGainM: elevation.gainM > 0 ? elevation.gainM : activity.totalElevationGain,
            elevationLossM: elevation.lossM,
            duration: Double(activity.movingTimeSeconds),
            averageHeartRate: avgHR ?? activity.averageHeartRate.map { Int($0) },
            maxHeartRate: maxHR ?? activity.maxHeartRate.map { Int($0) },
            averagePaceSecondsPerKm: pace,
            gpsTrack: trackPoints,
            splits: splits,
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: "Imported from Strava: \(activity.name)",
            pausedDuration: 0,
            stravaActivityId: activity.id,
            isStravaImport: true
        )

        try await runRepository.saveRun(run)
        Logger.strava.info("Imported Strava activity \(activity.id) as run \(run.id)")
        return run
    }

    // MARK: - Fetch Streams

    private func fetchStreams(activityId: Int, token: String) async throws -> [TrackPoint] {
        let url = URL(
            string: "\(AppConfiguration.Strava.apiBaseURL)/activities/\(activityId)/streams?keys=time,latlng,altitude,heartrate&key_type=distance"
        )!

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            Logger.strava.warning("Could not fetch streams for activity \(activityId), importing without GPS data")
            return []
        }

        let streams = try JSONDecoder().decode([StravaStream].self, from: data)
        return buildTrackPoints(from: streams, activityId: activityId)
    }

    private func buildTrackPoints(from streams: [StravaStream], activityId: Int) -> [TrackPoint] {
        let timeStream = streams.first { $0.type == "time" }
        let latlngStream = streams.first { $0.type == "latlng" }
        let altitudeStream = streams.first { $0.type == "altitude" }
        let hrStream = streams.first { $0.type == "heartrate" }

        guard let latlngData = latlngStream?.dataLatLng else {
            Logger.strava.info("No latlng stream for activity \(activityId)")
            return []
        }

        let timeData = timeStream?.dataInt ?? []
        let altitudeData = altitudeStream?.dataDouble ?? []
        let hrData = hrStream?.dataInt ?? []

        let baseTime = Date.now

        return latlngData.enumerated().compactMap { index, coords in
            guard coords.count == 2 else { return nil }
            let lat = coords[0]
            let lon = coords[1]

            guard (-90...90).contains(lat), (-180...180).contains(lon) else { return nil }

            let timestamp = index < timeData.count
                ? baseTime.addingTimeInterval(Double(timeData[index]))
                : baseTime.addingTimeInterval(Double(index))
            let altitude = index < altitudeData.count ? altitudeData[index] : 0
            let hr = index < hrData.count ? hrData[index] : nil

            return TrackPoint(
                latitude: lat,
                longitude: lon,
                altitudeM: altitude,
                timestamp: timestamp,
                heartRate: hr
            )
        }
    }

    // MARK: - Duplicate Detection

    private func isDuplicate(dto: StravaActivityDTO, existingRuns: [CompletedRun]) -> Bool {
        existingRuns.contains { run in
            if run.stravaActivityId == dto.id { return true }
            let timeDiff = abs(run.date.timeIntervalSince(dto.startDate))
            let distanceDiff = abs(run.distanceKm - dto.distance / 1000.0)
            return timeDiff < 3600 && distanceDiff < 0.5
        }
    }
}

// MARK: - DTOs

private struct StravaActivityDTO: Decodable {
    let id: Int
    let name: String
    let type: String
    let startDate: Date
    let distance: Double
    let movingTime: Int
    let totalElevationGain: Double
    let averageHeartrate: Double?
    let maxHeartrate: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, type, distance
        case startDate = "start_date"
        case movingTime = "moving_time"
        case totalElevationGain = "total_elevation_gain"
        case averageHeartrate = "average_heartrate"
        case maxHeartrate = "max_heartrate"
    }
}

private struct StravaStream: Decodable {
    let type: String
    let dataInt: [Int]?
    let dataDouble: [Double]?
    let dataLatLng: [[Double]]?

    enum CodingKeys: String, CodingKey {
        case type
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)

        switch type {
        case "latlng":
            dataLatLng = try container.decodeIfPresent([[Double]].self, forKey: .data)
            dataInt = nil
            dataDouble = nil
        case "altitude":
            dataDouble = try container.decodeIfPresent([Double].self, forKey: .data)
            dataInt = nil
            dataLatLng = nil
        case "time", "heartrate":
            dataInt = try container.decodeIfPresent([Int].self, forKey: .data)
            dataDouble = nil
            dataLatLng = nil
        default:
            dataInt = nil
            dataDouble = nil
            dataLatLng = nil
        }
    }
}
