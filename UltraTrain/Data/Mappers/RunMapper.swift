import Foundation

enum RunMapper {
    static func toUploadDTO(_ run: CompletedRun) -> RunUploadRequestDTO {
        let formatter = ISO8601DateFormatter()
        return RunUploadRequestDTO(
            id: run.id.uuidString,
            date: formatter.string(from: run.date),
            distanceKm: run.distanceKm,
            elevationGainM: run.elevationGainM,
            elevationLossM: run.elevationLossM,
            duration: run.duration,
            averageHeartRate: run.averageHeartRate,
            maxHeartRate: run.maxHeartRate,
            averagePaceSecondsPerKm: run.averagePaceSecondsPerKm,
            gpsTrack: run.gpsTrack.map { toTrackPointDTO($0) },
            splits: run.splits.map { toSplitDTO($0) },
            notes: run.notes,
            idempotencyKey: run.id.uuidString
        )
    }

    private static func toTrackPointDTO(_ point: TrackPoint) -> TrackPointDTO {
        let formatter = ISO8601DateFormatter()
        return TrackPointDTO(
            latitude: point.latitude,
            longitude: point.longitude,
            altitudeM: point.altitudeM,
            timestamp: formatter.string(from: point.timestamp),
            heartRate: point.heartRate
        )
    }

    private static func toSplitDTO(_ split: Split) -> SplitDTO {
        SplitDTO(
            id: split.id.uuidString,
            kilometerNumber: split.kilometerNumber,
            duration: split.duration,
            elevationChangeM: split.elevationChangeM,
            averageHeartRate: split.averageHeartRate
        )
    }
}
