import Foundation
import os

enum SharedRunRemoteMapper {
    static func toDomain(_ dto: SharedRunResponseDTO) -> SharedRun? {
        guard let id = UUID(uuidString: dto.id) else { return nil }

        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dto.date),
              let sharedAt = formatter.date(from: dto.sharedAt) else {
            return nil
        }

        guard InputValidator.isValidDistance(dto.distanceKm) else {
            Logger.validation.warning("SharedRunMapper: invalid distance \(dto.distanceKm)")
            return nil
        }
        guard InputValidator.isValidElevation(dto.elevationGainM),
              InputValidator.isValidElevation(dto.elevationLossM) else {
            Logger.validation.warning("SharedRunMapper: invalid elevation")
            return nil
        }
        guard InputValidator.isValidDuration(dto.duration) else {
            Logger.validation.warning("SharedRunMapper: invalid duration \(dto.duration)")
            return nil
        }
        if !InputValidator.isValidPace(dto.averagePace) {
            Logger.validation.warning("SharedRunMapper: pace \(dto.averagePace) outside expected range")
        }

        var filteredCount = 0
        let trackPoints = (dto.gpsTrack ?? []).compactMap { point -> TrackPoint? in
            guard let timestamp = formatter.date(from: point.timestamp) else { return nil }
            guard InputValidator.isValidCoordinate(latitude: point.latitude, longitude: point.longitude) else {
                filteredCount += 1
                return nil
            }
            let alt = InputValidator.isValidAltitude(point.altitudeM) ? point.altitudeM : 0
            let hr = InputValidator.isValidOptionalHeartRate(point.heartRate) ? point.heartRate : nil
            return TrackPoint(
                latitude: point.latitude,
                longitude: point.longitude,
                altitudeM: alt,
                timestamp: timestamp,
                heartRate: hr
            )
        }
        if filteredCount > 0 {
            Logger.validation.info("SharedRunMapper: filtered \(filteredCount) invalid GPS points")
        }

        let splits = (dto.splits ?? []).compactMap { split -> Split? in
            guard let splitId = UUID(uuidString: split.id) else { return nil }
            return Split(
                id: splitId,
                kilometerNumber: split.kilometerNumber,
                duration: split.duration,
                elevationChangeM: split.elevationChangeM,
                averageHeartRate: split.averageHeartRate
            )
        }

        return SharedRun(
            id: id,
            sharedByProfileId: dto.sharedByProfileId,
            sharedByDisplayName: InputValidator.sanitizeName(dto.sharedByDisplayName),
            date: date,
            distanceKm: dto.distanceKm,
            elevationGainM: dto.elevationGainM,
            elevationLossM: dto.elevationLossM,
            duration: dto.duration,
            averagePaceSecondsPerKm: dto.averagePace,
            gpsTrack: trackPoints,
            splits: splits,
            notes: InputValidator.sanitizeOptionalText(dto.notes, maxLength: 2000),
            sharedAt: sharedAt,
            likeCount: dto.likeCount,
            commentCount: dto.commentCount
        )
    }

    static func toDTO(_ run: SharedRun, recipientIds: [String]) -> ShareRunRequestDTO {
        let formatter = ISO8601DateFormatter()
        return ShareRunRequestDTO(
            id: run.id.uuidString,
            date: formatter.string(from: run.date),
            distanceKm: run.distanceKm,
            elevationGainM: run.elevationGainM,
            elevationLossM: run.elevationLossM,
            duration: run.duration,
            averagePace: run.averagePaceSecondsPerKm,
            gpsTrack: run.gpsTrack.map { toTrackPointDTO($0) },
            splits: run.splits.map { toSplitDTO($0) },
            notes: run.notes,
            recipientProfileIds: recipientIds,
            idempotencyKey: UUID().uuidString
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
