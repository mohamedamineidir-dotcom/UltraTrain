import Foundation
import Testing
@testable import UltraTrain

@Suite("WatchRunImportService Tests")
struct WatchRunImportServiceTests {

    private func makeWatchRunData(
        runId: UUID = UUID(),
        distanceKm: Double = 10.0,
        linkedSessionId: UUID? = nil,
        trackPoints: [WatchTrackPoint] = [],
        splits: [WatchSplit] = []
    ) -> WatchCompletedRunData {
        WatchCompletedRunData(
            runId: runId,
            date: .now,
            distanceKm: distanceKm,
            elevationGainM: 300,
            elevationLossM: 280,
            duration: 3600,
            pausedDuration: 30,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            trackPoints: trackPoints,
            splits: splits,
            linkedSessionId: linkedSessionId
        )
    }

    private func makeWatchTrackPoint() -> WatchTrackPoint {
        WatchTrackPoint(
            latitude: 45.0,
            longitude: 6.0,
            altitudeM: 1000,
            timestamp: .now,
            heartRate: 150
        )
    }

    private func makeWatchSplit(km: Int = 1) -> WatchSplit {
        WatchSplit(
            id: UUID(),
            kilometerNumber: km,
            duration: 360,
            elevationChangeM: 30,
            averageHeartRate: 150
        )
    }

    private func makeService(
        runRepo: MockRunRepository = MockRunRepository(),
        planRepo: MockTrainingPlanRepository = MockTrainingPlanRepository()
    ) -> (WatchRunImportService, MockRunRepository, MockTrainingPlanRepository) {
        let widgetWriter = WidgetDataWriter(
            planRepository: planRepo,
            runRepository: runRepo,
            raceRepository: MockRaceRepository()
        )
        let service = WatchRunImportService(
            runRepository: runRepo,
            planRepository: planRepo,
            widgetDataWriter: widgetWriter
        )
        return (service, runRepo, planRepo)
    }

    // MARK: - Basic Import

    @Test("importWatchRun saves the run to repository")
    func importSavesRun() async throws {
        let (service, runRepo, _) = makeService()
        let athleteId = UUID()
        let data = makeWatchRunData(distanceKm: 15.5)

        try await service.importWatchRun(data, athleteId: athleteId)

        #expect(runRepo.savedRun != nil)
        #expect(runRepo.savedRun?.distanceKm == 15.5)
        #expect(runRepo.savedRun?.athleteId == athleteId)
    }

    @Test("importWatchRun maps track points correctly")
    func importMapsTrackPoints() async throws {
        let (service, runRepo, _) = makeService()
        let athleteId = UUID()
        let tp = makeWatchTrackPoint()
        let data = makeWatchRunData(trackPoints: [tp])

        try await service.importWatchRun(data, athleteId: athleteId)

        #expect(runRepo.savedRun?.gpsTrack.count == 1)
        #expect(runRepo.savedRun?.gpsTrack.first?.latitude == 45.0)
        #expect(runRepo.savedRun?.gpsTrack.first?.longitude == 6.0)
        #expect(runRepo.savedRun?.gpsTrack.first?.altitudeM == 1000)
    }

    @Test("importWatchRun maps splits correctly")
    func importMapsSplits() async throws {
        let (service, runRepo, _) = makeService()
        let athleteId = UUID()
        let split = makeWatchSplit(km: 3)
        let data = makeWatchRunData(splits: [split])

        try await service.importWatchRun(data, athleteId: athleteId)

        #expect(runRepo.savedRun?.splits.count == 1)
        #expect(runRepo.savedRun?.splits.first?.kilometerNumber == 3)
        #expect(runRepo.savedRun?.splits.first?.duration == 360)
    }

    // MARK: - Linked Session

    @Test("importWatchRun marks linked session as completed")
    func importMarksLinkedSessionCompleted() async throws {
        let planRepo = MockTrainingPlanRepository()
        let sessionId = UUID()
        let runId = UUID()

        let session = TrainingSession(
            id: sessionId,
            date: .now,
            type: .longRun,
            plannedDistanceKm: 20,
            plannedElevationGainM: 500,
            plannedDuration: 7200,
            intensity: .moderate,
            description: "Long run",
            isCompleted: false,
            isSkipped: false
        )
        let week = TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: .now,
            endDate: Calendar.current.date(byAdding: .day, value: 6, to: .now)!,
            phase: .base,
            sessions: [session],
            isRecoveryWeek: false,
            targetVolumeKm: 60,
            targetElevationGainM: 1500
        )
        planRepo.activePlan = TrainingPlan(
            id: UUID(),
            athleteId: UUID(),
            targetRaceId: UUID(),
            createdAt: .now,
            weeks: [week],
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )

        let (service, _, _) = makeService(planRepo: planRepo)
        let data = makeWatchRunData(runId: runId, linkedSessionId: sessionId)

        try await service.importWatchRun(data, athleteId: UUID())

        // The plan should have been updated with the session marked completed
        let updatedPlan = planRepo.activePlan
        let updatedSession = updatedPlan?.weeks.first?.sessions.first
        #expect(updatedSession?.isCompleted == true)
        #expect(updatedSession?.linkedRunId == runId)
    }

    // MARK: - Error Handling

    @Test("importWatchRun throws when run repository fails")
    func importThrowsOnRepoError() async {
        let runRepo = MockRunRepository()
        runRepo.shouldThrow = true
        let (service, _, _) = makeService(runRepo: runRepo)

        let data = makeWatchRunData()

        await #expect(throws: DomainError.self) {
            try await service.importWatchRun(data, athleteId: UUID())
        }
    }

    @Test("importWatchRun sets notes to indicate Watch recording")
    func importSetsWatchNotes() async throws {
        let (service, runRepo, _) = makeService()
        let data = makeWatchRunData()

        try await service.importWatchRun(data, athleteId: UUID())

        #expect(runRepo.savedRun?.notes == "Recorded on Apple Watch")
    }
}
