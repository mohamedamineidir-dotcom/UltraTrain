import Foundation

enum SharedRunSwiftDataMapper {

    // MARK: - Codable Adapters

    private struct CodableTrackPoint: Codable {
        let latitude: Double
        let longitude: Double
        let altitudeM: Double
        let timestamp: Date
        let heartRate: Int?
    }

    private struct CodableSplit: Codable {
        let id: UUID
        let kilometerNumber: Int
        let duration: TimeInterval
        let elevationChangeM: Double
        let averageHeartRate: Int?
    }

    // MARK: - Domain -> SwiftData

    static func toSwiftData(_ run: SharedRun) -> SharedRunSwiftDataModel {
        SharedRunSwiftDataModel(
            id: run.id,
            sharedByProfileId: run.sharedByProfileId,
            sharedByDisplayName: run.sharedByDisplayName,
            date: run.date,
            distanceKm: run.distanceKm,
            elevationGainM: run.elevationGainM,
            elevationLossM: run.elevationLossM,
            duration: run.duration,
            averagePaceSecondsPerKm: run.averagePaceSecondsPerKm,
            gpsTrackData: encodeTrackPoints(run.gpsTrack),
            splitsData: encodeSplits(run.splits),
            notes: run.notes,
            sharedAt: run.sharedAt,
            likeCount: run.likeCount,
            commentCount: run.commentCount
        )
    }

    // MARK: - SwiftData -> Domain

    static func toDomain(_ model: SharedRunSwiftDataModel) -> SharedRun {
        SharedRun(
            id: model.id,
            sharedByProfileId: model.sharedByProfileId,
            sharedByDisplayName: model.sharedByDisplayName,
            date: model.date,
            distanceKm: model.distanceKm,
            elevationGainM: model.elevationGainM,
            elevationLossM: model.elevationLossM,
            duration: model.duration,
            averagePaceSecondsPerKm: model.averagePaceSecondsPerKm,
            gpsTrack: decodeTrackPoints(model.gpsTrackData),
            splits: decodeSplits(model.splitsData),
            notes: model.notes,
            sharedAt: model.sharedAt,
            likeCount: model.likeCount,
            commentCount: model.commentCount
        )
    }

    // MARK: - TrackPoint JSON

    private static func encodeTrackPoints(_ points: [TrackPoint]) -> Data {
        let codable = points.map { point in
            CodableTrackPoint(
                latitude: point.latitude,
                longitude: point.longitude,
                altitudeM: point.altitudeM,
                timestamp: point.timestamp,
                heartRate: point.heartRate
            )
        }
        return (try? JSONEncoder().encode(codable)) ?? Data()
    }

    private static func decodeTrackPoints(_ data: Data) -> [TrackPoint] {
        guard let codable = try? JSONDecoder().decode([CodableTrackPoint].self, from: data) else {
            return []
        }
        return codable.map { point in
            TrackPoint(
                latitude: point.latitude,
                longitude: point.longitude,
                altitudeM: point.altitudeM,
                timestamp: point.timestamp,
                heartRate: point.heartRate
            )
        }
    }

    // MARK: - Split JSON

    private static func encodeSplits(_ splits: [Split]) -> Data {
        let codable = splits.map { split in
            CodableSplit(
                id: split.id,
                kilometerNumber: split.kilometerNumber,
                duration: split.duration,
                elevationChangeM: split.elevationChangeM,
                averageHeartRate: split.averageHeartRate
            )
        }
        return (try? JSONEncoder().encode(codable)) ?? Data()
    }

    private static func decodeSplits(_ data: Data) -> [Split] {
        guard let codable = try? JSONDecoder().decode([CodableSplit].self, from: data) else {
            return []
        }
        return codable.map { split in
            Split(
                id: split.id,
                kilometerNumber: split.kilometerNumber,
                duration: split.duration,
                elevationChangeM: split.elevationChangeM,
                averageHeartRate: split.averageHeartRate
            )
        }
    }
}
