import Foundation
import os

final class DefaultRunImportUseCase: RunImportUseCase {
    private let gpxParser: GPXParser
    private let runRepository: any RunRepository
    private let logger = Logger.importData

    init(gpxParser: GPXParser, runRepository: any RunRepository) {
        self.gpxParser = gpxParser
        self.runRepository = runRepository
    }

    func importFromGPX(data: Data, athleteId: UUID) async throws -> CompletedRun {
        logger.info("Starting GPX import")

        let parseResult = try gpxParser.parse(data)

        guard parseResult.trackPoints.count >= 2 else {
            logger.error("GPX file has fewer than 2 track points")
            throw DomainError.importFailed(reason: "GPX file contains insufficient track points")
        }

        let points = parseResult.trackPoints
        let distanceKm = RunStatisticsCalculator.totalDistanceKm(points)
        let elevation = RunStatisticsCalculator.elevationChanges(points)
        let splits = RunStatisticsCalculator.buildSplits(from: points)

        let duration = points.last!.timestamp.timeIntervalSince(points.first!.timestamp)
        guard duration > 0 else {
            logger.error("GPX file has zero or negative duration")
            throw DomainError.importFailed(reason: "GPX file has invalid timestamps")
        }

        let pace = RunStatisticsCalculator.averagePace(distanceKm: distanceKm, duration: duration)

        let heartRates = points.compactMap(\.heartRate)
        let avgHR = heartRates.isEmpty ? nil : heartRates.reduce(0, +) / heartRates.count
        let maxHR = heartRates.isEmpty ? nil : heartRates.max()

        let run = CompletedRun(
            id: UUID(),
            athleteId: athleteId,
            date: parseResult.date ?? points.first!.timestamp,
            distanceKm: distanceKm,
            elevationGainM: elevation.gainM,
            elevationLossM: elevation.lossM,
            duration: duration,
            averageHeartRate: avgHR,
            maxHeartRate: maxHR,
            averagePaceSecondsPerKm: pace,
            gpsTrack: points,
            splits: splits,
            notes: parseResult.name.map { "Imported: \($0)" },
            pausedDuration: 0
        )

        try await runRepository.saveRun(run)
        logger.info("GPX import complete: \(String(format: "%.2f", distanceKm))km, \(splits.count) splits")

        return run
    }
}
