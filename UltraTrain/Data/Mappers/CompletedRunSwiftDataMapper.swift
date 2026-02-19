import Foundation

enum CompletedRunSwiftDataMapper {

    // MARK: - Codable Adapter

    private struct CodableTrackPoint: Codable {
        let latitude: Double
        let longitude: Double
        let altitudeM: Double
        let timestamp: Date
        let heartRate: Int?
    }

    private struct CodableIntakeEntry: Codable {
        let id: UUID
        let reminderType: String
        let status: String
        let elapsedTimeSeconds: TimeInterval
        let message: String
    }

    // MARK: - Domain -> SwiftData

    static func toSwiftData(_ run: CompletedRun) -> CompletedRunSwiftDataModel {
        let trackData = encodeTrackPoints(run.gpsTrack)
        let splitModels = run.splits.map { splitToSwiftData($0) }
        let intakeData = encodeIntakeEntries(run.nutritionIntakeLog)

        return CompletedRunSwiftDataModel(
            id: run.id,
            athleteId: run.athleteId,
            date: run.date,
            distanceKm: run.distanceKm,
            elevationGainM: run.elevationGainM,
            elevationLossM: run.elevationLossM,
            duration: run.duration,
            averageHeartRate: run.averageHeartRate,
            maxHeartRate: run.maxHeartRate,
            averagePaceSecondsPerKm: run.averagePaceSecondsPerKm,
            gpsTrackData: trackData,
            splits: splitModels,
            linkedSessionId: run.linkedSessionId,
            linkedRaceId: run.linkedRaceId,
            notes: run.notes,
            pausedDuration: run.pausedDuration,
            gearIds: run.gearIds,
            nutritionIntakeData: intakeData
        )
    }

    // MARK: - SwiftData -> Domain

    static func toDomain(_ model: CompletedRunSwiftDataModel) -> CompletedRun {
        let trackPoints = decodeTrackPoints(model.gpsTrackData)
        let splits = model.splits
            .map { splitToDomain($0) }
            .sorted { $0.kilometerNumber < $1.kilometerNumber }

        let intakeLog = decodeIntakeEntries(model.nutritionIntakeData)

        return CompletedRun(
            id: model.id,
            athleteId: model.athleteId,
            date: model.date,
            distanceKm: model.distanceKm,
            elevationGainM: model.elevationGainM,
            elevationLossM: model.elevationLossM,
            duration: model.duration,
            averageHeartRate: model.averageHeartRate,
            maxHeartRate: model.maxHeartRate,
            averagePaceSecondsPerKm: model.averagePaceSecondsPerKm,
            gpsTrack: trackPoints,
            splits: splits,
            linkedSessionId: model.linkedSessionId,
            linkedRaceId: model.linkedRaceId,
            notes: model.notes,
            pausedDuration: model.pausedDuration,
            gearIds: model.gearIds,
            nutritionIntakeLog: intakeLog
        )
    }

    // MARK: - Split Mapping

    private static func splitToSwiftData(_ split: Split) -> SplitSwiftDataModel {
        SplitSwiftDataModel(
            id: split.id,
            kilometerNumber: split.kilometerNumber,
            duration: split.duration,
            elevationChangeM: split.elevationChangeM,
            averageHeartRate: split.averageHeartRate
        )
    }

    private static func splitToDomain(_ model: SplitSwiftDataModel) -> Split {
        Split(
            id: model.id,
            kilometerNumber: model.kilometerNumber,
            duration: model.duration,
            elevationChangeM: model.elevationChangeM,
            averageHeartRate: model.averageHeartRate
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

    // MARK: - IntakeEntry JSON

    private static func encodeIntakeEntries(_ entries: [NutritionIntakeEntry]) -> Data {
        let codable = entries.map { entry in
            CodableIntakeEntry(
                id: entry.id,
                reminderType: entry.reminderType.rawValue,
                status: entry.status.rawValue,
                elapsedTimeSeconds: entry.elapsedTimeSeconds,
                message: entry.message
            )
        }
        return (try? JSONEncoder().encode(codable)) ?? Data()
    }

    private static func decodeIntakeEntries(_ data: Data) -> [NutritionIntakeEntry] {
        guard let codable = try? JSONDecoder().decode([CodableIntakeEntry].self, from: data) else {
            return []
        }
        return codable.compactMap { entry in
            guard let type = NutritionReminderType(rawValue: entry.reminderType),
                  let status = NutritionIntakeStatus(rawValue: entry.status) else {
                return nil
            }
            return NutritionIntakeEntry(
                id: entry.id,
                reminderType: type,
                status: status,
                elapsedTimeSeconds: entry.elapsedTimeSeconds,
                message: entry.message
            )
        }
    }
}
