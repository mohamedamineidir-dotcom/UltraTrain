import Foundation
import Testing
@testable import UltraTrain

@Suite("Nutrition ViewModel Tests")
struct NutritionViewModelTests {

    private let raceId = UUID()

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
            id: raceId,
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

    private func makePlan() -> NutritionPlan {
        let entry1 = NutritionEntry(
            id: UUID(),
            product: DefaultProducts.gel,
            timingMinutes: 20,
            quantity: 1,
            notes: nil
        )
        let entry2 = NutritionEntry(
            id: UUID(),
            product: DefaultProducts.drink,
            timingMinutes: 60,
            quantity: 1,
            notes: nil
        )
        return NutritionPlan(
            id: UUID(),
            raceId: raceId,
            caloriesPerHour: 315,
            hydrationMlPerHour: 550,
            sodiumMgPerHour: 600,
            entries: [entry1, entry2],
            gutTrainingSessionIds: []
        )
    }

    private func makeTrainingPlan(athlete: Athlete, race: Race) -> TrainingPlan {
        let longSession = TrainingSession(
            id: UUID(),
            date: Date.now.startOfDay,
            type: .longRun,
            plannedDistanceKm: 35,
            plannedElevationGainM: 1000,
            plannedDuration: 3 * 3600,
            intensity: .easy,
            description: "Long run",
            nutritionNotes: "Practice race nutrition",
            isCompleted: false, isSkipped: false,
            linkedRunId: nil
        )
        let shortSession = TrainingSession(
            id: UUID(),
            date: Date.now.startOfDay.adding(days: 2),
            type: .longRun,
            plannedDistanceKm: 15,
            plannedElevationGainM: 400,
            plannedDuration: 1 * 3600,
            intensity: .easy,
            description: "Short long run",
            nutritionNotes: nil,
            isCompleted: false, isSkipped: false,
            linkedRunId: nil
        )
        let week = TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: Date.now.startOfWeek,
            endDate: Date.now.startOfWeek.adding(days: 6),
            phase: .base,
            sessions: [longSession, shortSession],
            isRecoveryWeek: false,
            targetVolumeKm: 50,
            targetElevationGainM: 1400
        )
        return TrainingPlan(
            id: UUID(),
            athleteId: athlete.id,
            targetRaceId: race.id,
            createdAt: .now,
            weeks: [week],
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )
    }

    @MainActor
    private func makeViewModel(
        nutritionRepo: MockNutritionRepository = MockNutritionRepository(),
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        raceRepo: MockRaceRepository = MockRaceRepository(),
        planRepo: MockTrainingPlanRepository = MockTrainingPlanRepository(),
        generator: MockGenerateNutritionPlanUseCase = MockGenerateNutritionPlanUseCase()
    ) -> NutritionViewModel {
        NutritionViewModel(
            nutritionRepository: nutritionRepo,
            athleteRepository: athleteRepo,
            raceRepository: raceRepo,
            planRepository: planRepo,
            nutritionGenerator: generator
        )
    }

    // MARK: - Load

    @Test("Load plan from repository")
    @MainActor
    func loadPlan() async {
        let race = makeRace()
        let plan = makePlan()

        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let nutritionRepo = MockNutritionRepository()
        nutritionRepo.plans[raceId] = plan
        nutritionRepo.savedProducts = DefaultProducts.all

        let vm = makeViewModel(nutritionRepo: nutritionRepo, raceRepo: raceRepo)
        await vm.loadPlan()

        #expect(vm.plan != nil)
        #expect(vm.plan?.id == plan.id)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
        #expect(!vm.products.isEmpty)
    }

    @Test("Load plan returns nil when no A-race")
    @MainActor
    func loadPlanNoARace() async {
        let vm = makeViewModel()
        await vm.loadPlan()

        #expect(vm.plan == nil)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load plan seeds default products when empty")
    @MainActor
    func loadPlanSeedsDefaults() async {
        let race = makeRace()

        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let nutritionRepo = MockNutritionRepository()

        let vm = makeViewModel(nutritionRepo: nutritionRepo, raceRepo: raceRepo)
        await vm.loadPlan()

        #expect(vm.products.count == DefaultProducts.all.count)
        #expect(nutritionRepo.savedProducts.count == DefaultProducts.all.count)
    }

    @Test("Load plan handles error")
    @MainActor
    func loadPlanError() async {
        let raceRepo = MockRaceRepository()
        raceRepo.shouldThrow = true

        let vm = makeViewModel(raceRepo: raceRepo)
        await vm.loadPlan()

        #expect(vm.plan == nil)
        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    // MARK: - Generate

    @Test("Generate plan saves and updates state")
    @MainActor
    func generatePlan() async {
        let athlete = makeAthlete()
        let race = makeRace()

        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = athlete
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let nutritionRepo = MockNutritionRepository()
        let generator = MockGenerateNutritionPlanUseCase()

        let vm = makeViewModel(
            nutritionRepo: nutritionRepo,
            athleteRepo: athleteRepo,
            raceRepo: raceRepo,
            generator: generator
        )

        await vm.generatePlan()

        #expect(vm.plan != nil)
        #expect(vm.isGenerating == false)
        #expect(vm.error == nil)
        #expect(generator.executeCallCount == 1)
        #expect(nutritionRepo.savedPlan != nil)
    }

    @Test("Generate plan fails without athlete")
    @MainActor
    func generatePlanNoAthlete() async {
        let race = makeRace()
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]

        let vm = makeViewModel(raceRepo: raceRepo)
        await vm.generatePlan()

        #expect(vm.plan == nil)
        #expect(vm.error != nil)
    }

    @Test("Generate plan fails without A-race")
    @MainActor
    func generatePlanNoRace() async {
        let athlete = makeAthlete()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = athlete

        let vm = makeViewModel(athleteRepo: athleteRepo)
        await vm.generatePlan()

        #expect(vm.plan == nil)
        #expect(vm.error != nil)
    }

    @Test("Generate plan links gut training sessions")
    @MainActor
    func generatePlanLinksGutTraining() async {
        let athlete = makeAthlete()
        let race = makeRace()
        let trainingPlan = makeTrainingPlan(athlete: athlete, race: race)

        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = athlete
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let planRepo = MockTrainingPlanRepository()
        planRepo.activePlan = trainingPlan
        let nutritionRepo = MockNutritionRepository()
        let generator = MockGenerateNutritionPlanUseCase()

        let vm = makeViewModel(
            nutritionRepo: nutritionRepo,
            athleteRepo: athleteRepo,
            raceRepo: raceRepo,
            planRepo: planRepo,
            generator: generator
        )

        await vm.generatePlan()

        // Only the long session (3h) qualifies, the short one (1h) does not
        #expect(vm.plan?.gutTrainingSessionIds.count == 1)
        let longSessionId = trainingPlan.weeks[0].sessions[0].id
        #expect(vm.plan?.gutTrainingSessionIds.first == longSessionId)
    }

    @Test("Generate plan handles generator error")
    @MainActor
    func generatePlanGeneratorError() async {
        let athlete = makeAthlete()
        let race = makeRace()

        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = athlete
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let generator = MockGenerateNutritionPlanUseCase()
        generator.shouldThrow = true

        let vm = makeViewModel(
            athleteRepo: athleteRepo,
            raceRepo: raceRepo,
            generator: generator
        )

        await vm.generatePlan()

        #expect(vm.plan == nil)
        #expect(vm.error != nil)
        #expect(vm.isGenerating == false)
    }

    // MARK: - Add Product

    @Test("Add product appends to list")
    @MainActor
    func addProduct() async {
        let newProduct = NutritionProduct(
            id: UUID(),
            name: "Custom Gel",
            type: .gel,
            caloriesPerServing: 110,
            carbsGramsPerServing: 28.0,
            sodiumMgPerServing: 80,
            caffeinated: false
        )

        let nutritionRepo = MockNutritionRepository()
        let vm = makeViewModel(nutritionRepo: nutritionRepo)

        await vm.addProduct(newProduct)

        #expect(vm.products.count == 1)
        #expect(vm.products.first?.name == "Custom Gel")
        #expect(nutritionRepo.savedProducts.count == 1)
    }

    @Test("Add product handles error")
    @MainActor
    func addProductError() async {
        let newProduct = NutritionProduct(
            id: UUID(),
            name: "Custom Gel",
            type: .gel,
            caloriesPerServing: 110,
            carbsGramsPerServing: 28.0,
            sodiumMgPerServing: 80,
            caffeinated: false
        )

        let nutritionRepo = MockNutritionRepository()
        nutritionRepo.shouldThrow = true
        let vm = makeViewModel(nutritionRepo: nutritionRepo)

        await vm.addProduct(newProduct)

        #expect(vm.products.isEmpty)
        #expect(vm.error != nil)
    }

    // MARK: - Computed Properties

    @Test("Total calories computed from entries")
    @MainActor
    func totalCalories() {
        let plan = makePlan()
        let vm = makeViewModel()
        vm.plan = plan

        // gel: 100 * 1 + drink: 80 * 1 = 180
        #expect(vm.totalCaloriesInPlan == 180)
    }

    @Test("Total sodium computed from entries")
    @MainActor
    func totalSodium() {
        let plan = makePlan()
        let vm = makeViewModel()
        vm.plan = plan

        // gel: 60 * 1 + drink: 300 * 1 = 360
        #expect(vm.totalSodiumInPlan == 360)
    }

    @Test("Gut training session count")
    @MainActor
    func gutTrainingCount() {
        let vm = makeViewModel()

        #expect(vm.gutTrainingSessionCount == 0)

        var plan = makePlan()
        plan.gutTrainingSessionIds = [UUID(), UUID(), UUID()]
        vm.plan = plan

        #expect(vm.gutTrainingSessionCount == 3)
    }

    @Test("Computed properties return zero when no plan")
    @MainActor
    func computedPropertiesNoPlan() {
        let vm = makeViewModel()

        #expect(vm.totalCaloriesInPlan == 0)
        #expect(vm.totalSodiumInPlan == 0)
        #expect(vm.gutTrainingSessionCount == 0)
    }
}
