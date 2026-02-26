import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalTrainingPlanRepository Tests")
@MainActor
struct LocalTrainingPlanRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            TrainingPlanSwiftDataModel.self,
            TrainingWeekSwiftDataModel.self,
            TrainingSessionSwiftDataModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeSession(
        id: UUID = UUID(),
        date: Date = Date(),
        type: SessionType = .longRun,
        plannedDistanceKm: Double = 20,
        plannedElevationGainM: Double = 800,
        plannedDuration: TimeInterval = 7200,
        intensity: Intensity = .moderate,
        description: String = "Long trail run",
        isCompleted: Bool = false,
        isSkipped: Bool = false,
        linkedRunId: UUID? = nil
    ) -> TrainingSession {
        TrainingSession(
            id: id,
            date: date,
            type: type,
            plannedDistanceKm: plannedDistanceKm,
            plannedElevationGainM: plannedElevationGainM,
            plannedDuration: plannedDuration,
            intensity: intensity,
            description: description,
            isCompleted: isCompleted,
            isSkipped: isSkipped,
            linkedRunId: linkedRunId
        )
    }

    private func makeWeek(
        id: UUID = UUID(),
        weekNumber: Int = 1,
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(6 * 86400),
        phase: TrainingPhase = .base,
        sessions: [TrainingSession] = [],
        isRecoveryWeek: Bool = false,
        targetVolumeKm: Double = 60,
        targetElevationGainM: Double = 2000
    ) -> TrainingWeek {
        TrainingWeek(
            id: id,
            weekNumber: weekNumber,
            startDate: startDate,
            endDate: endDate,
            phase: phase,
            sessions: sessions,
            isRecoveryWeek: isRecoveryWeek,
            targetVolumeKm: targetVolumeKm,
            targetElevationGainM: targetElevationGainM
        )
    }

    private func makePlan(
        id: UUID = UUID(),
        athleteId: UUID = UUID(),
        targetRaceId: UUID = UUID(),
        weeks: [TrainingWeek]? = nil,
        intermediateRaceIds: [UUID] = [],
        intermediateRaceSnapshots: [RaceSnapshot] = []
    ) -> TrainingPlan {
        let planWeeks = weeks ?? [
            makeWeek(weekNumber: 1, phase: .base, sessions: [
                makeSession(type: .longRun, plannedDistanceKm: 20),
                makeSession(type: .tempo, plannedDistanceKm: 10)
            ]),
            makeWeek(weekNumber: 2, phase: .base, sessions: [
                makeSession(type: .intervals, plannedDistanceKm: 8),
                makeSession(type: .recovery, plannedDistanceKm: 6)
            ])
        ]

        return TrainingPlan(
            id: id,
            athleteId: athleteId,
            targetRaceId: targetRaceId,
            createdAt: Date(),
            weeks: planWeeks,
            intermediateRaceIds: intermediateRaceIds,
            intermediateRaceSnapshots: intermediateRaceSnapshots
        )
    }

    // MARK: - Save & Fetch

    @Test("Save plan and fetch by ID returns the saved plan")
    func saveAndFetchById() async throws {
        let container = try makeContainer()
        let repo = LocalTrainingPlanRepository(modelContainer: container)
        let plan = makePlan()

        try await repo.savePlan(plan)
        let fetched = try await repo.getPlan(id: plan.id)

        #expect(fetched != nil)
        #expect(fetched?.id == plan.id)
        #expect(fetched?.athleteId == plan.athleteId)
        #expect(fetched?.targetRaceId == plan.targetRaceId)
        #expect(fetched?.weeks.count == 2)
    }

    @Test("Fetch plan with nonexistent ID returns nil")
    func fetchNonexistentPlanReturnsNil() async throws {
        let container = try makeContainer()
        let repo = LocalTrainingPlanRepository(modelContainer: container)

        let fetched = try await repo.getPlan(id: UUID())
        #expect(fetched == nil)
    }

    // MARK: - Get Active Plan

    @Test("Get active plan returns most recently created plan")
    func getActivePlanReturnsMostRecent() async throws {
        let container = try makeContainer()
        let repo = LocalTrainingPlanRepository(modelContainer: container)
        let athleteId1 = UUID()
        let athleteId2 = UUID()

        let plan1 = makePlan(athleteId: athleteId1)
        try await repo.savePlan(plan1)

        // Save another plan with a different athlete ID to avoid the overwrite logic
        let plan2 = makePlan(athleteId: athleteId2)
        try await repo.savePlan(plan2)

        let active = try await repo.getActivePlan()
        #expect(active != nil)
        // The most recently created plan should be returned
        #expect(active?.id == plan2.id)
    }

    @Test("Get active plan when no plans exist returns nil")
    func getActivePlanEmpty() async throws {
        let container = try makeContainer()
        let repo = LocalTrainingPlanRepository(modelContainer: container)

        let active = try await repo.getActivePlan()
        #expect(active == nil)
    }

    // MARK: - Save Overwrites Existing for Same Athlete

    @Test("Saving plan for same athlete deletes existing plan")
    func savePlanDeletesExistingForSameAthlete() async throws {
        let container = try makeContainer()
        let repo = LocalTrainingPlanRepository(modelContainer: container)
        let athleteId = UUID()

        let plan1 = makePlan(athleteId: athleteId)
        try await repo.savePlan(plan1)

        let plan2 = makePlan(athleteId: athleteId)
        try await repo.savePlan(plan2)

        // plan1 should have been deleted
        let oldPlan = try await repo.getPlan(id: plan1.id)
        #expect(oldPlan == nil)

        // plan2 should exist
        let newPlan = try await repo.getPlan(id: plan2.id)
        #expect(newPlan != nil)
        #expect(newPlan?.id == plan2.id)
    }

    // MARK: - Update Plan

    @Test("Update plan replaces the plan data")
    func updatePlanReplacesData() async throws {
        let container = try makeContainer()
        let repo = LocalTrainingPlanRepository(modelContainer: container)
        let planId = UUID()
        let athleteId = UUID()

        let original = makePlan(id: planId, athleteId: athleteId, weeks: [
            makeWeek(weekNumber: 1, phase: .base)
        ])
        try await repo.savePlan(original)

        let updated = TrainingPlan(
            id: planId,
            athleteId: athleteId,
            targetRaceId: original.targetRaceId,
            createdAt: original.createdAt,
            weeks: [
                makeWeek(weekNumber: 1, phase: .build),
                makeWeek(weekNumber: 2, phase: .build),
                makeWeek(weekNumber: 3, phase: .peak)
            ],
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )
        try await repo.updatePlan(updated)

        let fetched = try await repo.getPlan(id: planId)
        #expect(fetched != nil)
        #expect(fetched?.weeks.count == 3)
    }

    @Test("Update nonexistent plan throws trainingPlanNotFound")
    func updateNonexistentPlanThrows() async throws {
        let container = try makeContainer()
        let repo = LocalTrainingPlanRepository(modelContainer: container)
        let plan = makePlan()

        do {
            try await repo.updatePlan(plan)
            Issue.record("Expected DomainError.trainingPlanNotFound to be thrown")
        } catch let error as DomainError {
            #expect(error == .trainingPlanNotFound)
        }
    }

    // MARK: - Update Session

    @Test("Update session modifies session fields")
    func updateSessionModifiesFields() async throws {
        let container = try makeContainer()
        let repo = LocalTrainingPlanRepository(modelContainer: container)

        let sessionId = UUID()
        let session = makeSession(id: sessionId, type: .longRun, plannedDistanceKm: 25, isCompleted: false)
        let plan = makePlan(weeks: [
            makeWeek(weekNumber: 1, sessions: [session])
        ])

        try await repo.savePlan(plan)

        let runId = UUID()
        var updatedSession = session
        updatedSession.isCompleted = true
        updatedSession.linkedRunId = runId
        updatedSession.plannedDistanceKm = 28

        try await repo.updateSession(updatedSession)

        // Verify through the plan
        let fetched = try await repo.getPlan(id: plan.id)
        let fetchedSession = fetched?.weeks.first?.sessions.first
        #expect(fetchedSession?.isCompleted == true)
        #expect(fetchedSession?.linkedRunId == runId)
        #expect(fetchedSession?.plannedDistanceKm == 28)
    }

    @Test("Update session marking as skipped")
    func updateSessionMarkAsSkipped() async throws {
        let container = try makeContainer()
        let repo = LocalTrainingPlanRepository(modelContainer: container)

        let sessionId = UUID()
        let session = makeSession(id: sessionId, isCompleted: false, isSkipped: false)
        let plan = makePlan(weeks: [
            makeWeek(weekNumber: 1, sessions: [session])
        ])

        try await repo.savePlan(plan)

        var skippedSession = session
        skippedSession.isSkipped = true

        try await repo.updateSession(skippedSession)

        let fetched = try await repo.getPlan(id: plan.id)
        let fetchedSession = fetched?.weeks.first?.sessions.first
        #expect(fetchedSession?.isSkipped == true)
    }

    @Test("Update nonexistent session throws trainingPlanNotFound")
    func updateNonexistentSessionThrows() async throws {
        let container = try makeContainer()
        let repo = LocalTrainingPlanRepository(modelContainer: container)

        let session = makeSession()

        do {
            try await repo.updateSession(session)
            Issue.record("Expected DomainError.trainingPlanNotFound to be thrown")
        } catch let error as DomainError {
            #expect(error == .trainingPlanNotFound)
        }
    }

    // MARK: - Plan with Sessions Structure

    @Test("Plan preserves week numbers and session types through round-trip")
    func planPreservesStructure() async throws {
        let container = try makeContainer()
        let repo = LocalTrainingPlanRepository(modelContainer: container)

        let plan = makePlan(weeks: [
            makeWeek(weekNumber: 1, phase: .base, sessions: [
                makeSession(type: .longRun),
                makeSession(type: .recovery)
            ]),
            makeWeek(weekNumber: 2, phase: .build, sessions: [
                makeSession(type: .intervals),
                makeSession(type: .verticalGain),
                makeSession(type: .tempo)
            ])
        ])

        try await repo.savePlan(plan)
        let fetched = try await repo.getPlan(id: plan.id)

        #expect(fetched?.weeks.count == 2)
        #expect(fetched?.weeks[0].weekNumber == 1)
        #expect(fetched?.weeks[0].phase == .base)
        #expect(fetched?.weeks[0].sessions.count == 2)
        #expect(fetched?.weeks[1].weekNumber == 2)
        #expect(fetched?.weeks[1].phase == .build)
        #expect(fetched?.weeks[1].sessions.count == 3)
    }

    @Test("Plan preserves intermediate race data")
    func planPreservesIntermediateRaces() async throws {
        let container = try makeContainer()
        let repo = LocalTrainingPlanRepository(modelContainer: container)

        let raceId1 = UUID()
        let raceId2 = UUID()
        let snapshots = [
            RaceSnapshot(id: raceId1, date: Date(), priority: .bRace),
            RaceSnapshot(id: raceId2, date: Date().addingTimeInterval(86400 * 30), priority: .cRace)
        ]

        let plan = makePlan(
            intermediateRaceIds: [raceId1, raceId2],
            intermediateRaceSnapshots: snapshots
        )

        try await repo.savePlan(plan)
        let fetched = try await repo.getPlan(id: plan.id)

        #expect(fetched?.intermediateRaceIds.count == 2)
        #expect(fetched?.intermediateRaceIds.contains(raceId1) == true)
        #expect(fetched?.intermediateRaceIds.contains(raceId2) == true)
        #expect(fetched?.intermediateRaceSnapshots.count == 2)
    }

    @Test("Plan with recovery week flag is preserved")
    func recoveryWeekFlagPreserved() async throws {
        let container = try makeContainer()
        let repo = LocalTrainingPlanRepository(modelContainer: container)

        let plan = makePlan(weeks: [
            makeWeek(weekNumber: 1, isRecoveryWeek: false, targetVolumeKm: 80),
            makeWeek(weekNumber: 2, isRecoveryWeek: false, targetVolumeKm: 85),
            makeWeek(weekNumber: 3, isRecoveryWeek: false, targetVolumeKm: 90),
            makeWeek(weekNumber: 4, isRecoveryWeek: true, targetVolumeKm: 55)
        ])

        try await repo.savePlan(plan)
        let fetched = try await repo.getPlan(id: plan.id)

        #expect(fetched?.weeks.count == 4)
        #expect(fetched?.weeks[3].isRecoveryWeek == true)
        #expect(fetched?.weeks[3].targetVolumeKm == 55)
        #expect(fetched?.weeks[0].isRecoveryWeek == false)
    }
}
