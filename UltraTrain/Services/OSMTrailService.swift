import Foundation
import CoreLocation
import os

final class OSMTrailService: @unchecked Sendable {
    private let session: URLSession
    private let baseURL = URL(string: "https://overpass-api.de/api/interpreter")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func searchTrails(
        near coordinate: CLLocationCoordinate2D,
        radiusKm: Double = 10
    ) async throws -> [OSMTrailResult] {
        let radiusM = radiusKm * 1000
        let query = """
        [out:json][timeout:30];
        (
          way["highway"~"path|track|footway"]\
        (around:\(Int(radiusM)),\(coordinate.latitude),\(coordinate.longitude));
          relation["route"="hiking"]\
        (around:\(Int(radiusM)),\(coordinate.latitude),\(coordinate.longitude));
        );
        out geom;
        """
        return try await executeQuery(query)
    }

    func searchTrails(
        byName name: String,
        near coordinate: CLLocationCoordinate2D? = nil
    ) async throws -> [OSMTrailResult] {
        let nameFilter = "\"name\"~\"\(escapedOSMString(name))\",i"
        let areaFilter: String
        if let coord = coordinate {
            areaFilter = "(around:50000,\(coord.latitude),\(coord.longitude))"
        } else {
            areaFilter = ""
        }

        let query = """
        [out:json][timeout:30];
        (
          way[\(nameFilter)]["highway"~"path|track|footway"]\(areaFilter);
          relation[\(nameFilter)]["route"="hiking"]\(areaFilter);
        );
        out geom;
        """
        return try await executeQuery(query)
    }

    // MARK: - Private

    private func executeQuery(_ query: String) async throws -> [OSMTrailResult] {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )
        request.timeoutInterval = 30

        let encodedQuery = query.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? query
        let body = "data=\(encodedQuery)"
        request.httpBody = body.data(using: .utf8)

        Logger.routePlanning.debug("OSM query: \(query.prefix(200))")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DomainError.networkUnavailable
        }

        return try parseResponse(data)
    }

    private func parseResponse(_ data: Data) throws -> [OSMTrailResult] {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let elements = json?["elements"] as? [[String: Any]] else {
            return []
        }

        var results: [OSMTrailResult] = []

        for element in elements {
            guard let id = element["id"] as? Int else { continue }

            let tags = element["tags"] as? [String: String] ?? [:]
            let name = tags["name"] ?? "Unnamed Trail"

            var trackPoints: [TrackPoint] = []

            if let geometry = element["geometry"] as? [[String: Any]] {
                trackPoints = geometry.compactMap { parseGeometryPoint($0) }
            } else if let members = element["members"] as? [[String: Any]] {
                for member in members {
                    if let geometry = member["geometry"] as? [[String: Any]] {
                        trackPoints.append(
                            contentsOf: geometry.compactMap { parseGeometryPoint($0) }
                        )
                    }
                }
            }

            guard trackPoints.count >= 2 else { continue }

            let distanceKm = computeDistance(trackPoints)

            results.append(OSMTrailResult(
                id: String(id),
                name: name,
                distanceKm: distanceKm,
                trackPoints: trackPoints,
                tags: tags
            ))
        }

        return results.sorted { $0.distanceKm > $1.distanceKm }
    }

    private func parseGeometryPoint(_ point: [String: Any]) -> TrackPoint? {
        guard let lat = point["lat"] as? Double,
              let lon = point["lon"] as? Double else { return nil }
        return TrackPoint(
            latitude: lat,
            longitude: lon,
            altitudeM: 0,
            timestamp: Date.distantPast,
            heartRate: nil
        )
    }

    private func computeDistance(_ points: [TrackPoint]) -> Double {
        var total: Double = 0
        for idx in 1..<points.count {
            let loc1 = CLLocation(
                latitude: points[idx - 1].latitude,
                longitude: points[idx - 1].longitude
            )
            let loc2 = CLLocation(
                latitude: points[idx].latitude,
                longitude: points[idx].longitude
            )
            total += loc1.distance(from: loc2)
        }
        return total / 1000.0
    }

    private func escapedOSMString(_ string: String) -> String {
        string.replacingOccurrences(of: "\"", with: "\\\"")
    }
}
