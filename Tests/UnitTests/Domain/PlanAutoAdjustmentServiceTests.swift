import Foundation
import Testing
@testable import UltraTrain

@Suite("PlanAutoAdjustmentService Tests")
struct PlanAutoAdjustmentServiceTests {

    // MARK: - Helpers

    private func makeAthlete() -> Athlete {
        Athlete(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 55,
            maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 40,
            longestRunKm: 25,
            preferredUnit: .metric
        )
    }

    private func makeRace(
        id: UUID = UUID(),
        name: String = "B Race",
        date: Date? = nil,
        priority: RacePriority = .bRace
    ) -> Race {
        Race(
            id: id,
            name: name,
            date: date ?? Date.now.adding(weeks: 8),
            distanceKm: 50,
            elevationGainM: 2000,
            elevationLossM: 2000,
            priority: priority,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .moderate
        )
    }

    private func makeTargetRace() -> Race {
        Race(
            id: UUID(),
            name: "A Race",
            date: Date.now.adding(weeks: 16),
            distanceKm: 100,
            elevationGainM: 5000,
            elevationLossM: 5000,
            priority: .aRace,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .moderate
        )
    }

    private func makePlan(
        with intermediateRaces: [Race],
        completedSessionInWeek1: Bool = false
    ) -> TrainingPlan {
        let weekStart = Date.now.startOfWeek

        let session = TrainingSession(
            id: UUID(),
            date: weekStart,
            type: .longRun,
            plannedDistanceKm: 20,
            plannedElevationGainM: 500,
            plannedDuration: 7200,
            intensity: .moderate,
            description: "Long run",
            nutritionNotes: nil,
            isCompleted: completedSessionInWeek1,
            isSkipped: false,
            linkedRunId: completedSessionInWeek1 ? UUID() : nil
        )

        let week = TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: weekStart,
            endDate: weekStart.adding(days: 6),
            phase: .base,
            sessions: [session],
            isRecoveryWeek: false,
            targetVolumeKm: 40,
            targetElevationGainM: 1000
        )

        let snapshots = intermediateRaces.map {
            RaceSnapshot(id: $0.id, date: $0.date, priority: $0.priority)
        }

        return TrainingPlan(
            id: UUID(),
            athleteId: UUID(),
            targetRaceId: UUID(),
            createdAt: .now,
            weeks: [week],
            intermediateRaceIds: intermediateRaces.map(\.id),
            intermediateRaceSnapshots: snapshots
        )
    }

    private func makeSUT(
        planGenerator: MockGenerateTrainingPlanUseCase = MockGenerateTrainingPlanUseCase(),
        planRepository: MockTrainingPlanRepository = MockTrainingPlanRepository()
    ) -> (service: DefaultPlanAutoAdjustmentService, generator: MockGenerateTrainingPlanUseCase, repo: MockTrainingPlanRepository) {
        let service = DefaultPlanAutoAdjustmentService(
            planGenerator: planGenerator,
            planRepository: planRepository
        )
        return (service, planGenerator, planRepository)
    }

    // MARK: - Tests

    @Test("Returns nil when races unchanged")
    func returnsNilWhenUnchanged() async throws {
        let bRace = makeRace()
        let plan = makePlan(with: [bRace])
        let (service, generator, _) = makeSUT()

        let result = try await service.adjustPlanIfNeeded(
            currentPlan: plan,
            currentRaces: [bRace],
            athlete: makeAthlete(),
            targetRace: makeTargetRace()
        )

        #expect(result == nil)
        #expect(generator.executeCallCount == 0)
    }

    @Test("Returns new plan when a race is added")
    func returnsNewPlanWhenRaceAdded() async throws {
        let existingRace = makeRace(name: "Existing B")
        let plan = makePlan(with: [existingRace])

        let newRace = makeRace(name: "New C", priority: .cRace)
        let (service, generator, _) = makeSUT()

        let result = try await service.adjustPlanIfNeeded(
            currentPlan: plan,
            currentRaces: [existingRace, newRace],
            athlete: makeAthlete(),
            targetRace: makeTargetRace()
        )

        #expect(result != nil)
        #expect(generator.executeCallCount == 1)
    }

    @Test("Returns new plan when a race date changes")
    func returnsNewPlanWhenRaceDateChanges() async throws {
        let raceId = UUID()
        let originalRace = makeRace(id: raceId, date: Date.now.adding(weeks: 8))
        let plan = makePlan(with: [originalRace])

        var updatedRace = originalRace
        updatedRace.date = Date.now.adding(weeks: 10)

        let (service, generator, _) = makeSUT()

        let result = try await service.adjustPlanIfNeeded(
            currentPlan: plan,
            currentRaces: [updatedRace],
            athlete: makeAthlete(),
            targetRace: makeTargetRace()
        )

        #expect(result != nil)
        #expect(generator.executeCallCount == 1)
    }

    @Test("Returns new plan when a race priority changes")
    func returnsNewPlanWhenRacePriorityChanges() async throws {
        let raceId = UUID()
        let originalRace = makeRace(id: raceId, priority: .bRace)
        let plan = makePlan(with: [originalRace])

        var updatedRace = originalRace
        updatedRace.priority = .cRace

        let (service, generator, _) = makeSUT()

        let result = try await service.adjustPlanIfNeeded(
            currentPlan: plan,
            currentRaces: [updatedRace],
            athlete: makeAthlete(),
            targetRace: makeTargetRace()
        )

        #expect(result != nil)
        #expect(generator.executeCallCount == 1)
    }

    @Test("Returns new plan when a race is removed")
    func returnsNewPlanWhenRaceRemoved() async throws {
        let race = makeRace()
        let plan = makePlan(with: [race])

        let (service, generator, _) = makeSUT()

        let result = try await service.adjustPlanIfNeeded(
            currentPlan: plan,
            currentRaces: [],
            athlete: makeAthlete(),
            targetRace: makeTargetRace()
        )

        #expect(result != nil)
        #expect(generator.executeCallCount == 1)
    }

    @Test("Progress is preserved after adjustment")
    func progressPreservedAfterAdjustment() async throws {
        let bRace = makeRace()
        let plan = makePlan(with: [bRace], completedSessionInWeek1: true)

        // The new race triggers regeneration
        let newRace = makeRace(name: "New Race", priority: .cRace)

        let generator = MockGenerateTrainingPlanUseCase()
        // Generator returns a plan with the same structure (week 1, long run on same day)
        // so that progress can be restored
        let weekStart = Date.now.startOfWeek
        let freshSession = TrainingSession(
            id: UUID(),
            date: weekStart,
            type: .longRun,
            plannedDistanceKm: 22,
            plannedElevationGainM: 600,
            plannedDuration: 7800,
            intensity: .moderate,
            description: "Long run v2",
            nutritionNotes: nil,
            isCompleted: false,
            isSkipped: false,
            linkedRunId: nil
        )
        let freshWeek = TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: weekStart,
            endDate: weekStart.adding(days: 6),
            phase: .base,
            sessions: [freshSession],
            isRecoveryWeek: false,
            targetVolumeKm: 45,
            targetElevationGainM: 1200
        )
        generator.result = TrainingPlan(
            id: UUID(),
            athleteId: plan.athleteId,
            targetRaceId: plan.targetRaceId,
            createdAt: .now,
            weeks: [freshWeek],
            intermediateRaceIds: [bRace.id, newRace.id],
            intermediateRaceSnapshots: [
                RaceSnapshot(id: bRace.id, date: bRace.date, priority: bRace.priority),
                RaceSnapshot(id: newRace.id, date: newRace.date, priority: newRace.priority)
            ]
        )

        let planRepo = MockTrainingPlanRepository()
        let (service, _, _) = makeSUT(planGenerator: generator, planRepository: planRepo)

        let result = try await service.adjustPlanIfNeeded(
            currentPlan: plan,
            currentRaces: [bRace, newRace],
            athlete: makeAthlete(),
            targetRace: makeTargetRace()
        )

        #expect(result != nil)
        // The restored session should be marked completed because the key matches
        let restoredSession = result!.weeks[0].sessions[0]
        #expect(restoredSession.isCompleted == true)
        #expect(restoredSession.linkedRunId != nil)
    }
}
