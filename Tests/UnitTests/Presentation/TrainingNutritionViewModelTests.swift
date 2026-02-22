import Foundation
import Testing
@testable import UltraTrain

@Suite("Training Nutrition ViewModel Tests")
struct TrainingNutritionViewModelTests {

    // MARK: - Test Helpers

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

    private func makeTrainingPlanWithTodaySession(
        athleteId: UUID,
        raceId: UUID
    ) -> TrainingPlan {
        let todaySession = TrainingSession(
            id: UUID(),
            date: Date.now.startOfDay,
            type: .longRun,
            plannedDistanceKm: 30,
            plannedElevationGainM: 800,
            plannedDuration: 3 * 3600,
            intensity: .easy,
            description: "Long run",
            nutritionNotes: nil,
            isCompleted: false,
            isSkipped: false,
            linkedRunId: nil
        )
        let week = TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: Date.now.startOfWeek,
            endDate: Date.now.startOfWeek.adding(days: 6),
            phase: .build,
            sessions: [todaySession],
            isRecoveryWeek: false,
            targetVolumeKm: 50,
            targetElevationGainM: 1200
        )
        return TrainingPlan(
            id: UUID(),
            athleteId: athleteId,
            targetRaceId: raceId,
            createdAt: .now,
            weeks: [week],
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )
    }

    private func makeFoodLogEntry(
        calories: Int? = 400,
        carbs: Double? = 50,
        protein: Double? = 20,
        fat: Double? = 10,
        hydration: Int? = 300,
        mealType: MealType = .breakfast
    ) -> FoodLogEntry {
        FoodLogEntry(
            id: UUID(),
            date: Date.now,
            mealType: mealType,
            description: "Test food",
            caloriesEstimate: calories,
            carbsGrams: carbs,
            proteinGrams: protein,
            fatGrams: fat,
            hydrationMl: hydration,
            productId: nil
        )
    }

    @MainActor
    private func makeViewModel(
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        planRepo: MockTrainingPlanRepository = MockTrainingPlanRepository(),
        nutritionRepo: MockNutritionRepository = MockNutritionRepository(),
        foodLogRepo: MockFoodLogRepository = MockFoodLogRepository(),
        advisor: MockSessionNutritionAdvisor = MockSessionNutritionAdvisor()
    ) -> TrainingNutritionViewModel {
        TrainingNutritionViewModel(
            athleteRepository: athleteRepo,
            planRepository: planRepo,
            nutritionRepository: nutritionRepo,
            foodLogRepository: foodLogRepo,
            sessionNutritionAdvisor: advisor
        )
    }

    // MARK: - Load

    @Test("Load populates daily target and today entries")
    @MainActor
    func testLoad_populatesDailyTargetAndEntries() async {
        let athlete = makeAthlete()
        let plan = makeTrainingPlanWithTodaySession(
            athleteId: athlete.id,
            raceId: UUID()
        )

        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = athlete
        let planRepo = MockTrainingPlanRepository()
        planRepo.activePlan = plan

        let entry = makeFoodLogEntry()
        let foodLogRepo = MockFoodLogRepository()
        foodLogRepo.entries = [entry]

        let vm = makeViewModel(
            athleteRepo: athleteRepo,
            planRepo: planRepo,
            foodLogRepo: foodLogRepo
        )

        await vm.load()

        #expect(vm.dailyTarget != nil)
        #expect(vm.dailyTarget!.caloriesTarget > 0)
        #expect(!vm.todayEntries.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load without athlete profile leaves dailyTarget nil")
    @MainActor
    func testLoad_whenNoAthlete_dailyTargetIsNil() async {
        let vm = makeViewModel()
        await vm.load()

        #expect(vm.dailyTarget == nil)
        #expect(vm.isLoading == false)
    }

    @Test("Load with error sets error message")
    @MainActor
    func testLoad_whenError_setsErrorMessage() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.shouldThrow = true

        let vm = makeViewModel(athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    @Test("Load without training plan defaults to recovery phase")
    @MainActor
    func testLoad_whenNoPlan_defaultsToRecoveryPhase() async {
        let athlete = makeAthlete()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = athlete

        let vm = makeViewModel(athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.dailyTarget != nil)
        #expect(vm.currentPhase == .recovery)
        #expect(vm.todaySession == nil)
    }

    // MARK: - Consumed Totals

    @Test("Consumed calories sums calorie estimates from entries")
    @MainActor
    func testConsumedCalories_sumsCalorieEstimates() {
        let vm = makeViewModel()
        vm.todayEntries = [
            makeFoodLogEntry(calories: 400),
            makeFoodLogEntry(calories: 300),
            makeFoodLogEntry(calories: 250)
        ]

        #expect(vm.consumedCalories == 950)
    }

    @Test("Consumed calories ignores nil estimates")
    @MainActor
    func testConsumedCalories_whenNilEstimates_ignoresThem() {
        let vm = makeViewModel()
        vm.todayEntries = [
            makeFoodLogEntry(calories: 400),
            makeFoodLogEntry(calories: nil),
            makeFoodLogEntry(calories: 200)
        ]

        #expect(vm.consumedCalories == 600)
    }

    @Test("Consumed calories returns zero when no entries")
    @MainActor
    func testConsumedCalories_whenNoEntries_returnsZero() {
        let vm = makeViewModel()
        #expect(vm.consumedCalories == 0)
    }

    @Test("Consumed carbs sums carb grams from entries")
    @MainActor
    func testConsumedCarbs_sumsCarbGrams() {
        let vm = makeViewModel()
        vm.todayEntries = [
            makeFoodLogEntry(carbs: 50),
            makeFoodLogEntry(carbs: 30)
        ]

        #expect(vm.consumedCarbs == 80.0)
    }

    @Test("Consumed protein sums protein grams from entries")
    @MainActor
    func testConsumedProtein_sumsProteinGrams() {
        let vm = makeViewModel()
        vm.todayEntries = [
            makeFoodLogEntry(protein: 20),
            makeFoodLogEntry(protein: 25)
        ]

        #expect(vm.consumedProtein == 45.0)
    }

    @Test("Consumed fat sums fat grams from entries")
    @MainActor
    func testConsumedFat_sumsFatGrams() {
        let vm = makeViewModel()
        vm.todayEntries = [
            makeFoodLogEntry(fat: 10),
            makeFoodLogEntry(fat: 15)
        ]

        #expect(vm.consumedFat == 25.0)
    }

    @Test("Consumed hydration sums hydration ml from entries")
    @MainActor
    func testConsumedHydration_sumsHydrationMl() {
        let vm = makeViewModel()
        vm.todayEntries = [
            makeFoodLogEntry(hydration: 300),
            makeFoodLogEntry(hydration: 500)
        ]

        #expect(vm.consumedHydration == 800)
    }

    // MARK: - Add Entry

    @Test("Add entry appends to today entries")
    @MainActor
    func testAddEntry_appendsToTodayEntries() async {
        let foodLogRepo = MockFoodLogRepository()
        let vm = makeViewModel(foodLogRepo: foodLogRepo)

        let entry = makeFoodLogEntry()
        await vm.addEntry(entry)

        #expect(vm.todayEntries.count == 1)
        #expect(vm.todayEntries.first?.id == entry.id)
        #expect(foodLogRepo.entries.count == 1)
    }

    @Test("Add entry also appends to weekly entries")
    @MainActor
    func testAddEntry_appendsToWeeklyEntries() async {
        let vm = makeViewModel()
        let entry = makeFoodLogEntry()
        await vm.addEntry(entry)

        #expect(vm.weeklyEntries.count == 1)
    }

    @Test("Add entry handles error")
    @MainActor
    func testAddEntry_whenError_setsErrorMessage() async {
        let foodLogRepo = MockFoodLogRepository()
        foodLogRepo.shouldThrow = true

        let vm = makeViewModel(foodLogRepo: foodLogRepo)
        let entry = makeFoodLogEntry()
        await vm.addEntry(entry)

        #expect(vm.error != nil)
        #expect(vm.todayEntries.isEmpty)
    }

    // MARK: - Delete Entry

    @Test("Delete entry removes from today entries")
    @MainActor
    func testDeleteEntry_removesFromTodayEntries() async {
        let entry = makeFoodLogEntry()
        let foodLogRepo = MockFoodLogRepository()
        foodLogRepo.entries = [entry]

        let vm = makeViewModel(foodLogRepo: foodLogRepo)
        vm.todayEntries = [entry]
        vm.weeklyEntries = [entry]

        await vm.deleteEntry(id: entry.id)

        #expect(vm.todayEntries.isEmpty)
        #expect(vm.weeklyEntries.isEmpty)
        #expect(foodLogRepo.entries.isEmpty)
    }

    @Test("Delete entry handles error")
    @MainActor
    func testDeleteEntry_whenError_setsErrorMessage() async {
        let entry = makeFoodLogEntry()
        let foodLogRepo = MockFoodLogRepository()
        foodLogRepo.shouldThrow = true

        let vm = makeViewModel(foodLogRepo: foodLogRepo)
        vm.todayEntries = [entry]

        await vm.deleteEntry(id: entry.id)

        #expect(vm.error != nil)
        // Entry remains since delete failed
        #expect(vm.todayEntries.count == 1)
    }
}
