import Foundation

enum SavedRouteSwiftDataMapper {

    // MARK: - Codable Adapters

    private struct CodableTrackPoint: Codable {
        let latitude: Double
        let longitude: Double
        let altitudeM: Double
        let timestamp: Date
        let heartRate: Int?
    }

    private struct CodableCheckpoint: Codable {
        let id: UUID
        let name: String
        let distanceFromStartKm: Double
        let elevationM: Double
        let hasAidStation: Bool
    }

    // MARK: - Domain -> SwiftData

    static func toSwiftData(_ route: SavedRoute) -> SavedRouteSwiftDataModel {
        SavedRouteSwiftDataModel(
            id: route.id,
            name: route.name,
            distanceKm: route.distanceKm,
            elevationGainM: route.elevationGainM,
            elevationLossM: route.elevationLossM,
            trackPointsData: encodeTrackPoints(route.trackPoints),
            courseRouteData: encodeTrackPoints(route.courseRoute),
            checkpointsData: encodeCheckpoints(route.checkpoints),
            sourceRaw: route.source.rawValue,
            createdAt: route.createdAt,
            notes: route.notes,
            sourceRunId: route.sourceRunId
        )
    }

    // MARK: - SwiftData -> Domain

    static func toDomain(_ model: SavedRouteSwiftDataModel) -> SavedRoute? {
        guard let source = RouteSource(rawValue: model.sourceRaw) else { return nil }

        return SavedRoute(
            id: model.id,
            name: model.name,
            distanceKm: model.distanceKm,
            elevationGainM: model.elevationGainM,
            elevationLossM: model.elevationLossM,
            trackPoints: decodeTrackPoints(model.trackPointsData),
            courseRoute: decodeTrackPoints(model.courseRouteData),
            checkpoints: decodeCheckpoints(model.checkpointsData),
            source: source,
            createdAt: model.createdAt,
            notes: model.notes,
            sourceRunId: model.sourceRunId
        )
    }

    // MARK: - TrackPoint JSON

    private static func encodeTrackPoints(_ points: [TrackPoint]) -> Data {
        let codable = points.map {
            CodableTrackPoint(
                latitude: $0.latitude,
                longitude: $0.longitude,
                altitudeM: $0.altitudeM,
                timestamp: $0.timestamp,
                heartRate: $0.heartRate
            )
        }
        return (try? JSONEncoder().encode(codable)) ?? Data()
    }

    private static func decodeTrackPoints(_ data: Data) -> [TrackPoint] {
        guard let codable = try? JSONDecoder().decode([CodableTrackPoint].self, from: data) else {
            return []
        }
        return codable.map {
            TrackPoint(
                latitude: $0.latitude,
                longitude: $0.longitude,
                altitudeM: $0.altitudeM,
                timestamp: $0.timestamp,
                heartRate: $0.heartRate
            )
        }
    }

    // MARK: - Checkpoint JSON

    private static func encodeCheckpoints(_ checkpoints: [Checkpoint]) -> Data {
        let codable = checkpoints.map {
            CodableCheckpoint(
                id: $0.id,
                name: $0.name,
                distanceFromStartKm: $0.distanceFromStartKm,
                elevationM: $0.elevationM,
                hasAidStation: $0.hasAidStation
            )
        }
        return (try? JSONEncoder().encode(codable)) ?? Data()
    }

    private static func decodeCheckpoints(_ data: Data) -> [Checkpoint] {
        guard let codable = try? JSONDecoder().decode([CodableCheckpoint].self, from: data) else {
            return []
        }
        return codable.map {
            Checkpoint(
                id: $0.id,
                name: $0.name,
                distanceFromStartKm: $0.distanceFromStartKm,
                elevationM: $0.elevationM,
                hasAidStation: $0.hasAidStation
            )
        }
    }
}
