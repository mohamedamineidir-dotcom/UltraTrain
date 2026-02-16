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
}
