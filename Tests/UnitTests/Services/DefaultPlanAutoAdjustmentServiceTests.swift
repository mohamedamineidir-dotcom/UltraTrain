import Foundation
import Testing
@testable import UltraTrain

@Suite("DefaultPlanAutoAdjustmentService Tests")
struct DefaultPlanAutoAdjustmentServiceTests {

    private func makeAthlete() -> Athlete {
        Athlete(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 50,
            maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 60,
            longestRunKm: 30,
            preferredUnit: .metric
        )
    }

    private func makeRace(
        id: UUID = UUID(),
        priority: RacePriority = .aRace,
        date: Date = Calendar.current.date(byAdding: .month, value: 3, to: .now)!
    ) -> Race {
        Race(
            id: id,
            name: "Test Race",
            date: date,
            distanceKm: 100,
            elevationGainM: 5000,
            elevationLossM: 5000,
            priority: priority,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .moderate
        )
    }

    private func makeSession(
        id: UUID = UUID(),
        isCompleted: Bool = false,
        isSkipped: Bool = false,
        linkedRunId: UUID? = nil
    ) -> TrainingSession {
        TrainingSession(
            id: id,
            date: .now,
            type: .longRun,
            plannedDistanceKm: 20,
            plannedElevationGainM: 500,
            plannedDuration: 7200,
            intensity: .moderate,
            description: "Long run",
            isCompleted: isCompleted,
            isSkipped: isSkipped,
            linkedRunId: linkedRunId
        )
    }

    private func makeWeek(sessions: [TrainingSession] = []) -> TrainingWeek {
        TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: .now,
            endDate: Calendar.current.date(byAdding: .day, value: 6, to: .now)!,
            phase: .base,
            sessions: sessions,
            isRecoveryWeek: false,
            targetVolumeKm: 60,
            targetElevationGainM: 1500
        )
    }

    private func makePlan(
        athleteId: UUID,
        targetRaceId: UUID,
        weeks: [TrainingWeek] = [],
        intermediateRaceSnapshots: [RaceSnapshot] = []
    ) -> TrainingPlan {
        TrainingPlan(
            id: UUID(),
            athleteId: athleteId,
            targetRaceId: targetRaceId,
            createdAt: .now,
            weeks: weeks,
            intermediateRaceIds: intermediateRaceSnapshots.map(\.id),
            intermediateRaceSnapshots: intermediateRaceSnapshots
        )
    }

    // MARK: - No Change Needed

    @Test("adjustPlanIfNeeded returns nil when races unchanged")
    func noAdjustmentWhenRacesUnchanged() async throws {
        let mockPlanGen = MockGenerateTrainingPlanUseCase()
        let mockPlanRepo = MockTrainingPlanRepository()
        let service = DefaultPlanAutoAdjustmentService(
            planGenerator: mockPlanGen,
            planRepository: mockPlanRepo
        )

        let raceId = UUID()
        let raceDate = Calendar.current.date(byAdding: .month, value: 1, to: .now)!
        let race = makeRace(id: raceId, priority: .bRace, date: raceDate)
        let athlete = makeAthlete()
        let targetRace = makeRace()

        let snapshot = RaceSnapshot(id: raceId, date: raceDate, priority: .bRace)
        let plan = makePlan(
            athleteId: athlete.id,
            targetRaceId: targetRace.id,
            intermediateRaceSnapshots: [snapshot]
        )

        let result = try await service.adjustPlanIfNeeded(
            currentPlan: plan,
            currentRaces: [race],
            athlete: athlete,
            targetRace: targetRace
        )

        #expect(result == nil)
        #expect(mockPlanGen.executeCallCount == 0)
    }

    // MARK: - Adjustment Triggered

    @Test("adjustPlanIfNeeded regenerates plan when races changed")
    func adjustmentTriggeredWhenRacesChanged() async throws {
        let mockPlanGen = MockGenerateTrainingPlanUseCase()
        let mockPlanRepo = MockTrainingPlanRepository()
        let service = DefaultPlanAutoAdjustmentService(
            planGenerator: mockPlanGen,
            planRepository: mockPlanRepo
        )

        let athlete = makeAthlete()
        let targetRace = makeRace()

        // Plan has no intermediate race snapshots
        let plan = makePlan(
            athleteId: athlete.id,
            targetRaceId: targetRace.id,
            intermediateRaceSnapshots: []
        )

        // But now there is a new intermediate race
        let newRace = makeRace(priority: .bRace)

        let result = try await service.adjustPlanIfNeeded(
            currentPlan: plan,
            currentRaces: [newRace],
            athlete: athlete,
            targetRace: targetRace
        )

        #expect(result != nil)
        #expect(mockPlanGen.executeCallCount == 1)
        #expect(mockPlanRepo.activePlan != nil)
    }

    // MARK: - Error Propagation

    @Test("adjustPlanIfNeeded propagates generator errors")
    func adjustmentPropagatesGeneratorError() async throws {
        let mockPlanGen = MockGenerateTrainingPlanUseCase()
        mockPlanGen.shouldThrow = true
        let mockPlanRepo = MockTrainingPlanRepository()
        let service = DefaultPlanAutoAdjustmentService(
            planGenerator: mockPlanGen,
            planRepository: mockPlanRepo
        )

        let athlete = makeAthlete()
        let targetRace = makeRace()
        let plan = makePlan(
            athleteId: athlete.id,
            targetRaceId: targetRace.id,
            intermediateRaceSnapshots: []
        )

        let newRace = makeRace(priority: .bRace)

        await #expect(throws: DomainError.self) {
            try await service.adjustPlanIfNeeded(
                currentPlan: plan,
                currentRaces: [newRace],
                athlete: athlete,
                targetRace: targetRace
            )
        }
    }

    // MARK: - Completed Sessions Persisted

    @Test("adjustPlanIfNeeded saves completed sessions from new plan")
    func adjustmentSavesCompletedSessions() async throws {
        let mockPlanGen = MockGenerateTrainingPlanUseCase()
        let mockPlanRepo = MockTrainingPlanRepository()
        let service = DefaultPlanAutoAdjustmentService(
            planGenerator: mockPlanGen,
            planRepository: mockPlanRepo
        )

        let athlete = makeAthlete()
        let targetRace = makeRace()

        let completedSession = makeSession(isCompleted: true, linkedRunId: UUID())
        let week = makeWeek(sessions: [completedSession])

        // Set up the mock generator to return a plan with completed sessions
        mockPlanGen.result = TrainingPlan(
            id: UUID(),
            athleteId: athlete.id,
            targetRaceId: targetRace.id,
            createdAt: .now,
            weeks: [week],
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )

        let plan = makePlan(
            athleteId: athlete.id,
            targetRaceId: targetRace.id,
            intermediateRaceSnapshots: []
        )

        let newRace = makeRace(priority: .cRace)

        let result = try await service.adjustPlanIfNeeded(
            currentPlan: plan,
            currentRaces: [newRace],
            athlete: athlete,
            targetRace: targetRace
        )

        #expect(result != nil)
        #expect(mockPlanRepo.updatedSessions.count == 1)
        #expect(mockPlanRepo.updatedSessions[0].isCompleted)
    }

    @Test("adjustPlanIfNeeded propagates repository save error")
    func adjustmentPropagatesRepositoryError() async throws {
        let mockPlanGen = MockGenerateTrainingPlanUseCase()
        let mockPlanRepo = MockTrainingPlanRepository()
        mockPlanRepo.shouldThrow = true
        let service = DefaultPlanAutoAdjustmentService(
            planGenerator: mockPlanGen,
            planRepository: mockPlanRepo
        )

        let athlete = makeAthlete()
        let targetRace = makeRace()
        let plan = makePlan(
            athleteId: athlete.id,
            targetRaceId: targetRace.id,
            intermediateRaceSnapshots: []
        )

        let newRace = makeRace(priority: .bRace)

        await #expect(throws: DomainError.self) {
            try await service.adjustPlanIfNeeded(
                currentPlan: plan,
                currentRaces: [newRace],
                athlete: athlete,
                targetRace: targetRace
            )
        }
    }
}
