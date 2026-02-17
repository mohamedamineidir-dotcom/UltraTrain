import Foundation
import Testing
@testable import UltraTrain

@Suite("Training Plan ViewModel Tests")
struct TrainingPlanViewModelTests {

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

    private func makeRace() -> Race {
        Race(
            id: UUID(),
            name: "Test Ultra",
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

    private func makePlan(athlete: Athlete, race: Race) -> TrainingPlan {
        let week = TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: Date.now.startOfWeek,
            endDate: Date.now.startOfWeek.adding(days: 6),
            phase: .base,
            sessions: [
                TrainingSession(
                    id: UUID(),
                    date: Date.now.startOfDay,
                    type: .rest,
                    plannedDistanceKm: 0,
                    plannedElevationGainM: 0,
                    plannedDuration: 0,
                    intensity: .easy,
                    description: "Rest day",
                    nutritionNotes: nil,
                    isCompleted: false, isSkipped: false,
                    linkedRunId: nil
                ),
                TrainingSession(
                    id: UUID(),
                    date: Date.now.startOfDay.adding(days: 1),
                    type: .tempo,
                    plannedDistanceKm: 10,
                    plannedElevationGainM: 200,
                    plannedDuration: 3600,
                    intensity: .moderate,
                    description: "Tempo run",
                    nutritionNotes: nil,
                    isCompleted: false, isSkipped: false,
                    linkedRunId: nil
                )
            ],
            isRecoveryWeek: false,
            targetVolumeKm: 40,
            targetElevationGainM: 800
        )

        return TrainingPlan(
            id: UUID(),
            athleteId: athlete.id,
            targetRaceId: race.id,
            createdAt: .now,
            weeks: [week],
            intermediateRaceIds: []
        )
    }

    @MainActor
    private func makeViewModel(
        planRepo: MockTrainingPlanRepository = MockTrainingPlanRepository(),
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        raceRepo: MockRaceRepository = MockRaceRepository(),
        generator: MockGenerateTrainingPlanUseCase = MockGenerateTrainingPlanUseCase()
    ) -> TrainingPlanViewModel {
        TrainingPlanViewModel(
            planRepository: planRepo,
            athleteRepository: athleteRepo,
            raceRepository: raceRepo,
            planGenerator: generator,
            nutritionRepository: MockNutritionRepository(),
            nutritionAdvisor: DefaultSessionNutritionAdvisor()
        )
    }

    // MARK: - Load

    @Test("Load plan from repository")
    @MainActor
    func loadPlan() async {
        let athlete = makeAthlete()
        let race = makeRace()
        let plan = makePlan(athlete: athlete, race: race)

        let planRepo = MockTrainingPlanRepository()
        planRepo.activePlan = plan

        let vm = makeViewModel(planRepo: planRepo)
        await vm.loadPlan()

        #expect(vm.plan != nil)
        #expect(vm.plan?.id == plan.id)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load plan handles nil")
    @MainActor
    func loadPlanNil() async {
        let vm = makeViewModel()
        await vm.loadPlan()

        #expect(vm.plan == nil)
        #expect(vm.error == nil)
    }

    @Test("Load plan handles error")
    @MainActor
    func loadPlanError() async {
        let planRepo = MockTrainingPlanRepository()
        planRepo.shouldThrow = true

        let vm = makeViewModel(planRepo: planRepo)
        await vm.loadPlan()

        #expect(vm.plan == nil)
        #expect(vm.error != nil)
    }

    // MARK: - Generate

    @Test("Generate plan saves and updates state")
    @MainActor
    func generatePlan() async {
        let athlete = makeAthlete()
        let race = makeRace()
        let plan = makePlan(athlete: athlete, race: race)

        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = athlete
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let generator = MockGenerateTrainingPlanUseCase()
        generator.result = plan
        let planRepo = MockTrainingPlanRepository()

        let vm = makeViewModel(
            planRepo: planRepo,
            athleteRepo: athleteRepo,
            raceRepo: raceRepo,
            generator: generator
        )

        await vm.generatePlan()

        #expect(vm.plan != nil)
        #expect(vm.plan?.id == plan.id)
        #expect(vm.isGenerating == false)
        #expect(vm.error == nil)
        #expect(generator.executeCallCount == 1)
        #expect(planRepo.activePlan != nil)
    }

    @Test("Generate plan fails without athlete")
    @MainActor
    func generatePlanNoAthlete() async {
        let vm = makeViewModel()
        await vm.generatePlan()

        #expect(vm.plan == nil)
        #expect(vm.error != nil)
    }

    @Test("Generate plan fails when generator throws")
    @MainActor
    func generatePlanGeneratorError() async {
        let athlete = makeAthlete()
        let race = makeRace()

        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = athlete
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let generator = MockGenerateTrainingPlanUseCase()
        generator.shouldThrow = true

        let vm = makeViewModel(
            athleteRepo: athleteRepo,
            raceRepo: raceRepo,
            generator: generator
        )

        await vm.generatePlan()

        #expect(vm.plan == nil)
        #expect(vm.error != nil)
    }

    // MARK: - Toggle Session

    @Test("Toggle session completion updates plan")
    @MainActor
    func toggleSession() async {
        let athlete = makeAthlete()
        let race = makeRace()
        let plan = makePlan(athlete: athlete, race: race)
        let planRepo = MockTrainingPlanRepository()

        let vm = makeViewModel(planRepo: planRepo)
        vm.plan = plan

        // Toggle the tempo session (index 1)
        await vm.toggleSessionCompletion(weekIndex: 0, sessionIndex: 1)

        #expect(vm.plan?.weeks[0].sessions[1].isCompleted == true)
        #expect(planRepo.updatedSession != nil)
        #expect(planRepo.updatedSession?.isCompleted == true)
    }

    @Test("Toggle session handles error gracefully")
    @MainActor
    func toggleSessionError() async {
        let athlete = makeAthlete()
        let race = makeRace()
        let plan = makePlan(athlete: athlete, race: race)
        let planRepo = MockTrainingPlanRepository()
        planRepo.shouldThrow = true

        let vm = makeViewModel(planRepo: planRepo)
        vm.plan = plan

        await vm.toggleSessionCompletion(weekIndex: 0, sessionIndex: 1)

        #expect(vm.error != nil)
    }

    // MARK: - Computed Properties

    @Test("Next session skips rest days")
    @MainActor
    func nextSessionSkipsRest() {
        let athlete = makeAthlete()
        let race = makeRace()
        let plan = makePlan(athlete: athlete, race: race)

        let vm = makeViewModel()
        vm.plan = plan

        let next = vm.nextSession
        // Should return the tempo session, not the rest session
        #expect(next?.type == .tempo)
    }

    @Test("Weekly progress counts active sessions")
    @MainActor
    func weeklyProgress() {
        let athlete = makeAthlete()
        let race = makeRace()
        let plan = makePlan(athlete: athlete, race: race)

        let vm = makeViewModel()
        vm.plan = plan

        let progress = vm.weeklyProgress
        // 1 active session (tempo), rest doesn't count
        #expect(progress.total == 1)
        #expect(progress.completed == 0)
    }

    // MARK: - Stale Plan Detection

    @Test("isPlanStale true when B/C races differ from plan")
    @MainActor
    func isPlanStaleWhenRacesChanged() {
        let race = makeRace()
        let bRace = Race(
            id: UUID(), name: "B Race",
            date: Date.now.adding(weeks: 8),
            distanceKm: 50, elevationGainM: 2000, elevationLossM: 2000,
            priority: .bRace, goalType: .finish, checkpoints: [],
            terrainDifficulty: .easy
        )
        let plan = makePlan(athlete: makeAthlete(), race: race)

        let vm = makeViewModel()
        vm.plan = plan
        vm.races = [race, bRace]

        #expect(vm.isPlanStale == true)
    }

    @Test("isPlanStale false when races match plan")
    @MainActor
    func isPlanStaleWhenMatching() {
        let race = makeRace()
        let bRaceId = UUID()
        let bRace = Race(
            id: bRaceId, name: "B Race",
            date: Date.now.adding(weeks: 8),
            distanceKm: 50, elevationGainM: 2000, elevationLossM: 2000,
            priority: .bRace, goalType: .finish, checkpoints: [],
            terrainDifficulty: .easy
        )
        var plan = makePlan(athlete: makeAthlete(), race: race)
        plan.intermediateRaceIds = [bRaceId]

        let vm = makeViewModel()
        vm.plan = plan
        vm.races = [race, bRace]

        #expect(vm.isPlanStale == false)
    }

    @Test("isPlanStale false when no plan exists")
    @MainActor
    func isPlanStaleNoPlan() {
        let vm = makeViewModel()
        #expect(vm.isPlanStale == false)
    }

    @Test("Races load alongside plan")
    @MainActor
    func racesLoadWithPlan() async {
        let race = makeRace()
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let planRepo = MockTrainingPlanRepository()
        planRepo.activePlan = makePlan(athlete: makeAthlete(), race: race)

        let vm = makeViewModel(planRepo: planRepo, raceRepo: raceRepo)
        await vm.loadPlan()

        #expect(vm.races.count == 1)
        #expect(vm.races.first?.id == race.id)
    }

    @Test("targetRace returns A-race")
    @MainActor
    func targetRaceComputed() {
        let aRace = makeRace()
        let bRace = Race(
            id: UUID(), name: "B",
            date: Date.now.adding(weeks: 8),
            distanceKm: 30, elevationGainM: 1000, elevationLossM: 1000,
            priority: .bRace, goalType: .finish, checkpoints: [],
            terrainDifficulty: .easy
        )

        let vm = makeViewModel()
        vm.races = [bRace, aRace]

        #expect(vm.targetRace?.id == aRace.id)
    }

    @Test("isPlanStale ignores A-race changes")
    @MainActor
    func isPlanStaleIgnoresARace() {
        let race = makeRace()
        let plan = makePlan(athlete: makeAthlete(), race: race)
        // Different A-race ID doesn't make plan stale (only intermediate races matter)
        let differentARace = Race(
            id: UUID(), name: "Different A",
            date: Date.now.adding(weeks: 20),
            distanceKm: 80, elevationGainM: 4000, elevationLossM: 4000,
            priority: .aRace, goalType: .finish, checkpoints: [],
            terrainDifficulty: .moderate
        )

        let vm = makeViewModel()
        vm.plan = plan
        vm.races = [differentARace]

        // No intermediate races, plan has no intermediate race IDs — should match
        #expect(vm.isPlanStale == false)
    }

    // MARK: - Refresh Races

    @Test("Refresh races updates races without affecting plan")
    @MainActor
    func refreshRacesUpdatesList() async {
        let race = makeRace()
        let plan = makePlan(athlete: makeAthlete(), race: race)
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let planRepo = MockTrainingPlanRepository()
        planRepo.activePlan = plan

        let vm = makeViewModel(planRepo: planRepo, raceRepo: raceRepo)
        await vm.loadPlan()

        // Add a B-race to the repository
        let bRace = Race(
            id: UUID(), name: "B Race",
            date: Date.now.adding(weeks: 8),
            distanceKm: 50, elevationGainM: 2000, elevationLossM: 2000,
            priority: .bRace, goalType: .finish, checkpoints: [],
            terrainDifficulty: .easy
        )
        raceRepo.races.append(bRace)

        await vm.refreshRaces()

        #expect(vm.races.count == 2)
        #expect(vm.plan?.id == plan.id) // Plan unchanged
    }

    @Test("isPlanStale true after refreshRaces detects new B-race")
    @MainActor
    func isPlanStaleAfterRefresh() async {
        let race = makeRace()
        let plan = makePlan(athlete: makeAthlete(), race: race)
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]

        let vm = makeViewModel(raceRepo: raceRepo)
        vm.plan = plan
        vm.races = [race]
        #expect(vm.isPlanStale == false)

        // Add B-race to repo and refresh
        let bRace = Race(
            id: UUID(), name: "B Race",
            date: Date.now.adding(weeks: 8),
            distanceKm: 50, elevationGainM: 2000, elevationLossM: 2000,
            priority: .bRace, goalType: .finish, checkpoints: [],
            terrainDifficulty: .easy
        )
        raceRepo.races.append(bRace)
        await vm.refreshRaces()

        #expect(vm.isPlanStale == true)
    }

    // MARK: - Race Change Summary

    @Test("raceChangeSummary returns added races")
    @MainActor
    func raceChangeSummaryAdded() {
        let race = makeRace()
        let plan = makePlan(athlete: makeAthlete(), race: race)
        let bRace = Race(
            id: UUID(), name: "Trail 50K",
            date: Date.now.adding(weeks: 8),
            distanceKm: 50, elevationGainM: 2000, elevationLossM: 2000,
            priority: .bRace, goalType: .finish, checkpoints: [],
            terrainDifficulty: .easy
        )

        let vm = makeViewModel()
        vm.plan = plan
        vm.races = [race, bRace]

        let summary = vm.raceChangeSummary
        #expect(summary.added.count == 1)
        #expect(summary.added.first?.name == "Trail 50K")
        #expect(summary.removed.isEmpty)
    }

    @Test("raceChangeSummary returns removed race IDs")
    @MainActor
    func raceChangeSummaryRemoved() {
        let race = makeRace()
        let removedId = UUID()
        var plan = makePlan(athlete: makeAthlete(), race: race)
        plan.intermediateRaceIds = [removedId]

        let vm = makeViewModel()
        vm.plan = plan
        vm.races = [race] // No intermediate races anymore

        let summary = vm.raceChangeSummary
        #expect(summary.added.isEmpty)
        #expect(summary.removed.count == 1)
        #expect(summary.removed.first == removedId)
    }

    @Test("raceChangeSummary empty when no changes")
    @MainActor
    func raceChangeSummaryEmpty() {
        let race = makeRace()
        let bRaceId = UUID()
        let bRace = Race(
            id: bRaceId, name: "B Race",
            date: Date.now.adding(weeks: 8),
            distanceKm: 50, elevationGainM: 2000, elevationLossM: 2000,
            priority: .bRace, goalType: .finish, checkpoints: [],
            terrainDifficulty: .easy
        )
        var plan = makePlan(athlete: makeAthlete(), race: race)
        plan.intermediateRaceIds = [bRaceId]

        let vm = makeViewModel()
        vm.plan = plan
        vm.races = [race, bRace]

        let summary = vm.raceChangeSummary
        #expect(summary.added.isEmpty)
        #expect(summary.removed.isEmpty)
    }

    // MARK: - Progress Preservation

    @Test("Generate plan preserves completed session status")
    @MainActor
    func generatePlanPreservesCompleted() async {
        let athlete = makeAthlete()
        let race = makeRace()
        var plan = makePlan(athlete: athlete, race: race)
        // Mark the tempo session (index 1) as completed
        plan.weeks[0].sessions[1].isCompleted = true

        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = athlete
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let planRepo = MockTrainingPlanRepository()
        let generator = MockGenerateTrainingPlanUseCase()
        // Generator returns a plan with same structure (same week number, session types, dates)
        generator.result = makePlan(athlete: athlete, race: race)

        let vm = makeViewModel(
            planRepo: planRepo,
            athleteRepo: athleteRepo,
            raceRepo: raceRepo,
            generator: generator
        )
        vm.plan = plan

        await vm.generatePlan()

        // The tempo session should still be completed after regeneration
        #expect(vm.plan?.weeks[0].sessions[1].isCompleted == true)
    }

    @Test("Generate plan preserves skipped session status")
    @MainActor
    func generatePlanPreservesSkipped() async {
        let athlete = makeAthlete()
        let race = makeRace()
        var plan = makePlan(athlete: athlete, race: race)
        // Mark the tempo session (index 1) as skipped
        plan.weeks[0].sessions[1].isSkipped = true

        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = athlete
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let planRepo = MockTrainingPlanRepository()
        let generator = MockGenerateTrainingPlanUseCase()
        generator.result = makePlan(athlete: athlete, race: race)

        let vm = makeViewModel(
            planRepo: planRepo,
            athleteRepo: athleteRepo,
            raceRepo: raceRepo,
            generator: generator
        )
        vm.plan = plan

        await vm.generatePlan()

        #expect(vm.plan?.weeks[0].sessions[1].isSkipped == true)
    }

    @Test("Generate plan does not preserve status for non-matching sessions")
    @MainActor
    func generatePlanNoPreserveNonMatching() async {
        let athlete = makeAthlete()
        let race = makeRace()
        var plan = makePlan(athlete: athlete, race: race)
        // Mark the rest session (index 0) as completed
        plan.weeks[0].sessions[0].isCompleted = true

        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = athlete
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let planRepo = MockTrainingPlanRepository()
        let generator = MockGenerateTrainingPlanUseCase()

        // Generator returns a plan with different session types (only tempo, no rest)
        let differentWeek = TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: Date.now.startOfWeek,
            endDate: Date.now.startOfWeek.adding(days: 6),
            phase: .base,
            sessions: [
                TrainingSession(
                    id: UUID(),
                    date: Date.now.startOfDay.adding(days: 1),
                    type: .intervals,
                    plannedDistanceKm: 8,
                    plannedElevationGainM: 100,
                    plannedDuration: 3600,
                    intensity: .hard,
                    description: "Intervals",
                    nutritionNotes: nil,
                    isCompleted: false, isSkipped: false,
                    linkedRunId: nil
                )
            ],
            isRecoveryWeek: false,
            targetVolumeKm: 40,
            targetElevationGainM: 800
        )
        generator.result = TrainingPlan(
            id: UUID(),
            athleteId: athlete.id,
            targetRaceId: race.id,
            createdAt: .now,
            weeks: [differentWeek],
            intermediateRaceIds: []
        )

        let vm = makeViewModel(
            planRepo: planRepo,
            athleteRepo: athleteRepo,
            raceRepo: raceRepo,
            generator: generator
        )
        vm.plan = plan

        await vm.generatePlan()

        // The intervals session should NOT be completed (no matching old session)
        #expect(vm.plan?.weeks[0].sessions[0].isCompleted == false)
    }
}
