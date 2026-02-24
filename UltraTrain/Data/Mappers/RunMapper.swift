import Foundation
import os

enum RunMapper {
    static func toDomain(_ dto: RunResponseDTO, athleteId: UUID) -> CompletedRun? {
        guard let id = UUID(uuidString: dto.id) else { return nil }

        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dto.date) else { return nil }

        guard InputValidator.isValidDistance(dto.distanceKm) else {
            Logger.validation.warning("RunMapper: invalid distance \(dto.distanceKm) for run \(dto.id)")
            return nil
        }
        guard InputValidator.isValidElevation(dto.elevationGainM),
              InputValidator.isValidElevation(dto.elevationLossM) else {
            Logger.validation.warning("RunMapper: invalid elevation for run \(dto.id)")
            return nil
        }
        guard InputValidator.isValidDuration(dto.duration) else {
            Logger.validation.warning("RunMapper: invalid duration \(dto.duration) for run \(dto.id)")
            return nil
        }

        if !InputValidator.isValidPace(dto.averagePaceSecondsPerKm) {
            Logger.validation.warning("RunMapper: pace \(dto.averagePaceSecondsPerKm) outside expected range for run \(dto.id)")
        }
        let validatedAvgHR = InputValidator.isValidOptionalHeartRate(dto.averageHeartRate)
            ? dto.averageHeartRate : nil
        let validatedMaxHR = InputValidator.isValidOptionalHeartRate(dto.maxHeartRate)
            ? dto.maxHeartRate : nil

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
            Logger.validation.info("RunMapper: filtered \(filteredCount) invalid GPS points for run \(dto.id)")
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

        let linkedSessionId: UUID? = dto.linkedSessionId.flatMap { UUID(uuidString: $0) }
        let serverUpdatedAt: Date? = dto.updatedAt.flatMap { formatter.date(from: $0) }
        let sanitizedNotes = InputValidator.sanitizeOptionalText(dto.notes, maxLength: 2000)

        return CompletedRun(
            id: id,
            athleteId: athleteId,
            date: date,
            distanceKm: dto.distanceKm,
            elevationGainM: dto.elevationGainM,
            elevationLossM: dto.elevationLossM,
            duration: dto.duration,
            averageHeartRate: validatedAvgHR,
            maxHeartRate: validatedMaxHR,
            averagePaceSecondsPerKm: dto.averagePaceSecondsPerKm,
            gpsTrack: trackPoints,
            splits: splits,
            linkedSessionId: linkedSessionId,
            notes: sanitizedNotes,
            pausedDuration: 0,
            serverUpdatedAt: serverUpdatedAt
        )
    }

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
            linkedSessionId: run.linkedSessionId?.uuidString,
            idempotencyKey: run.id.uuidString,
            clientUpdatedAt: run.serverUpdatedAt.map { formatter.string(from: $0) }
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
