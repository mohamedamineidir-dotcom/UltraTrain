import Foundation
import os

enum ElevationService {

    private static let batchSize = 100
    private static let apiURL = "https://api.open-elevation.com/api/v1/lookup"

    // MARK: - Smoothing

    static func smoothElevationProfile(
        _ profile: [ElevationProfilePoint],
        windowSize: Int = 5
    ) -> [ElevationProfilePoint] {
        guard profile.count >= windowSize, windowSize >= 3 else { return profile }

        let halfWindow = windowSize / 2
        return profile.enumerated().map { index, point in
            let start = max(0, index - halfWindow)
            let end = min(profile.count - 1, index + halfWindow)
            let window = profile[start...end]
            let avgAltitude = window.map(\.altitudeM).reduce(0, +) / Double(window.count)
            return ElevationProfilePoint(
                distanceKm: point.distanceKm,
                altitudeM: avgAltitude
            )
        }
    }

    // MARK: - Segment Categorization

    static func categorizeSegments(
        _ segments: [ElevationSegment]
    ) -> [(segment: ElevationSegment, category: GradientCategory)] {
        segments.map { segment in
            (segment, GradientCategory.from(gradient: segment.averageGradient))
        }
    }

    // MARK: - DEM Elevation Lookup

    /// Corrects GPS altitude with DEM data from Open-Elevation API.
    /// Sends coordinates in batches to avoid request size limits.
    /// Falls back to original GPS altitudes on failure.
    static func correctElevations(
        for coordinates: [(latitude: Double, longitude: Double)],
        session: URLSession = .shared
    ) async -> [Double] {
        guard !coordinates.isEmpty else { return [] }

        var elevations = [Double](repeating: 0, count: coordinates.count)
        let batches = stride(from: 0, to: coordinates.count, by: batchSize).map {
            Array(coordinates[$0..<min($0 + batchSize, coordinates.count)])
        }

        for (batchIndex, batch) in batches.enumerated() {
            do {
                let batchElevations = try await fetchElevations(for: batch, session: session)
                let offset = batchIndex * batchSize
                for (i, elev) in batchElevations.enumerated() {
                    elevations[offset + i] = elev
                }
            } catch {
                Logger.persistence.warning("DEM elevation lookup failed for batch \(batchIndex): \(error)")
                let offset = batchIndex * batchSize
                for (i, coord) in batch.enumerated() {
                    elevations[offset + i] = coord.longitude // GPS fallback not useful; leave 0
                }
                return [] // Return empty to signal failure — caller uses GPS data
            }
        }

        return elevations
    }

    /// Corrects an elevation profile using DEM data. Returns the corrected profile,
    /// or the original (smoothed) profile if the API call fails.
    static func correctElevationProfile(
        _ profile: [ElevationProfilePoint],
        coordinates: [(latitude: Double, longitude: Double)],
        session: URLSession = .shared
    ) async -> [ElevationProfilePoint] {
        guard profile.count == coordinates.count else {
            Logger.persistence.warning("Elevation profile / coordinate count mismatch")
            return smoothElevationProfile(profile)
        }

        let demElevations = await correctElevations(for: coordinates, session: session)
        guard demElevations.count == profile.count else {
            return smoothElevationProfile(profile)
        }

        let corrected = zip(profile, demElevations).map { point, demAltitude in
            ElevationProfilePoint(distanceKm: point.distanceKm, altitudeM: demAltitude)
        }
        return smoothElevationProfile(corrected)
    }

    // MARK: - Private

    private static func fetchElevations(
        for coordinates: [(latitude: Double, longitude: Double)],
        session: URLSession
    ) async throws -> [Double] {
        guard let url = URL(string: apiURL) else {
            throw DomainError.persistenceError(message: "Invalid elevation API URL")
        }

        let locations = coordinates.map { coord in
            ["latitude": coord.latitude, "longitude": coord.longitude]
        }
        let body = ["locations": locations]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DomainError.networkUnavailable
        }

        let decoded = try JSONDecoder().decode(OpenElevationResponse.self, from: data)
        return decoded.results.map(\.elevation)
    }
}

// MARK: - Open-Elevation API Response

private struct OpenElevationResponse: Decodable {
    let results: [ElevationResult]
}

private struct ElevationResult: Decodable {
    let latitude: Double
    let longitude: Double
    let elevation: Double
}
