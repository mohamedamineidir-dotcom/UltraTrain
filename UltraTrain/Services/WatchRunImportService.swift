import Foundation
import os

final class WatchRunImportService: Sendable {

    private let runRepository: any RunRepository
    private let planRepository: any TrainingPlanRepository
    private let widgetDataWriter: WidgetDataWriter

    init(
        runRepository: any RunRepository,
        planRepository: any TrainingPlanRepository,
        widgetDataWriter: WidgetDataWriter
    ) {
        self.runRepository = runRepository
        self.planRepository = planRepository
        self.widgetDataWriter = widgetDataWriter
    }

    func importWatchRun(_ data: WatchCompletedRunData, athleteId: UUID) async throws {
        let trackPoints = data.trackPoints.map { wp in
            TrackPoint(
                latitude: wp.latitude,
                longitude: wp.longitude,
                altitudeM: wp.altitudeM,
                timestamp: wp.timestamp,
                heartRate: wp.heartRate
            )
        }

        let splits = data.splits.map { ws in
            Split(
                id: ws.id,
                kilometerNumber: ws.kilometerNumber,
                duration: ws.duration,
                elevationChangeM: ws.elevationChangeM,
                averageHeartRate: ws.averageHeartRate
            )
        }

        let completedRun = CompletedRun(
            id: data.runId,
            athleteId: athleteId,
            date: data.date,
            distanceKm: data.distanceKm,
            elevationGainM: data.elevationGainM,
            elevationLossM: data.elevationLossM,
            duration: data.duration,
            averageHeartRate: data.averageHeartRate,
            maxHeartRate: data.maxHeartRate,
            averagePaceSecondsPerKm: data.averagePaceSecondsPerKm,
            gpsTrack: trackPoints,
            splits: splits,
            linkedSessionId: data.linkedSessionId,
            linkedRaceId: nil,
            notes: "Recorded on Apple Watch",
            pausedDuration: data.pausedDuration
        )

        try await runRepository.saveRun(completedRun)
        Logger.watch.info("Imported watch run: \(data.runId), \(data.distanceKm) km")

        // Mark linked session as completed
        if let sessionId = data.linkedSessionId {
            try await markSessionCompleted(sessionId: sessionId, runId: data.runId)
        }

        // Update widget data
        await widgetDataWriter.writeAll()
    }

    private func markSessionCompleted(sessionId: UUID, runId: UUID) async throws {
        guard var plan = try await planRepository.getActivePlan() else { return }
        for weekIndex in plan.weeks.indices {
            for sessionIndex in plan.weeks[weekIndex].sessions.indices {
                if plan.weeks[weekIndex].sessions[sessionIndex].id == sessionId {
                    plan.weeks[weekIndex].sessions[sessionIndex].isCompleted = true
                    plan.weeks[weekIndex].sessions[sessionIndex].linkedRunId = runId
                    try await planRepository.updatePlan(plan)
                    Logger.watch.info("Marked session \(sessionId) as completed from watch run")
                    return
                }
            }
        }
    }
}
