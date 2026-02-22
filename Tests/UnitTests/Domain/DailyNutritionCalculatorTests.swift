import Foundation
import Testing
@testable import UltraTrain

@Suite("Daily Nutrition Calculator Tests")
struct DailyNutritionCalculatorTests {

    // MARK: - Test Helpers

    private func makeAthlete(weightKg: Double = 70) -> Athlete {
        Athlete(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: weightKg,
            heightCm: 175,
            restingHeartRate: 55,
            maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 40,
            longestRunKm: 25,
            preferredUnit: .metric
        )
    }

    private func makeSession(
        type: SessionType,
        durationHours: Double = 1.0
    ) -> TrainingSession {
        TrainingSession(
            id: UUID(),
            date: Date.now,
            type: type,
            plannedDistanceKm: 10,
            plannedElevationGainM: 300,
            plannedDuration: durationHours * 3600,
            intensity: .moderate,
            description: "Test session",
            nutritionNotes: nil,
            isCompleted: false,
            isSkipped: false,
            linkedRunId: nil
        )
    }

    // MARK: - Rest Day Calorie Calculation

    @Test("Rest day calories equal weight times 30 with no activity addition")
    func testRestDayCalories_whenNoSession_equalsBaseCalories() {
        let athlete = makeAthlete(weightKg: 70)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            session: nil,
            preferences: .default
        )

        // Base: 70 * 30 = 2100, no activity addition
        #expect(target.caloriesTarget == 2100)
    }

    @Test("Rest day calories scale with body weight")
    func testRestDayCalories_whenHeavierAthlete_returnsHigherCalories() {
        let athlete = makeAthlete(weightKg: 85)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            session: nil,
            preferences: .default
        )

        // Base: 85 * 30 = 2550
        #expect(target.caloriesTarget == 2550)
    }

    // MARK: - Activity Calorie Addition

    @Test("Long run session adds activity calories based on duration")
    func testCalories_whenLongRunSession_addsActivityCalories() {
        let athlete = makeAthlete(weightKg: 70)
        let session = makeSession(type: .longRun, durationHours: 3.0)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            session: session,
            preferences: .default
        )

        // Base: 2100 + activity: 3.0 * 500 = 1500 => total = 3600
        #expect(target.caloriesTarget == 3600)
    }

    @Test("Tempo session adds higher activity calories per hour")
    func testCalories_whenTempoSession_addsHigherRate() {
        let athlete = makeAthlete(weightKg: 70)
        let session = makeSession(type: .tempo, durationHours: 1.5)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .build,
            session: session,
            preferences: .default
        )

        // Base: 2100 + activity: 1.5 * 600 = 900 => total = 3000
        #expect(target.caloriesTarget == 3000)
    }

    @Test("Intervals session adds 600 cal per hour")
    func testCalories_whenIntervalsSession_adds600PerHour() {
        let athlete = makeAthlete(weightKg: 70)
        let session = makeSession(type: .intervals, durationHours: 1.0)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .build,
            session: session,
            preferences: .default
        )

        // Base: 2100 + activity: 1.0 * 600 = 600 => total = 2700
        #expect(target.caloriesTarget == 2700)
    }

    @Test("Recovery session adds lower activity calories")
    func testCalories_whenRecoverySession_addsLowerRate() {
        let athlete = makeAthlete(weightKg: 70)
        let session = makeSession(type: .recovery, durationHours: 1.0)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            session: session,
            preferences: .default
        )

        // Base: 2100 + activity: 1.0 * 300 = 300 => total = 2400
        #expect(target.caloriesTarget == 2400)
    }

    @Test("Vertical gain session adds 550 cal per hour")
    func testCalories_whenVerticalGainSession_adds550PerHour() {
        let athlete = makeAthlete(weightKg: 70)
        let session = makeSession(type: .verticalGain, durationHours: 2.0)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .build,
            session: session,
            preferences: .default
        )

        // Base: 2100 + activity: 2.0 * 550 = 1100 => total = 3200
        #expect(target.caloriesTarget == 3200)
    }

    @Test("Rest session type adds zero activity calories")
    func testCalories_whenRestSessionType_addsZero() {
        let athlete = makeAthlete(weightKg: 70)
        let session = makeSession(type: .rest, durationHours: 0)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .recovery,
            session: session,
            preferences: .default
        )

        #expect(target.caloriesTarget == 2100)
    }

    @Test("Cross training session type adds zero activity calories")
    func testCalories_whenCrossTraining_addsZero() {
        let athlete = makeAthlete(weightKg: 70)
        let session = makeSession(type: .crossTraining, durationHours: 1.0)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            session: session,
            preferences: .default
        )

        #expect(target.caloriesTarget == 2100)
    }

    // MARK: - Base Phase Macro Split (55/20/25)

    @Test("Base phase uses 55/20/25 carbs/protein/fat split")
    func testMacroSplit_whenBasePhase_uses55_20_25() {
        let athlete = makeAthlete(weightKg: 70)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            session: nil,
            preferences: .default
        )

        // Total 2100 cal
        // Carbs: (2100 * 0.55) / 4 = 288
        // Protein: (2100 * 0.20) / 4 = 105
        // Fat: (2100 * 0.25) / 9 = 58
        #expect(target.carbsGramsTarget == 288)
        #expect(target.proteinGramsTarget == 105)
        #expect(target.fatGramsTarget == 58)
    }

    // MARK: - Build Phase Macro Split (55/22/23)

    @Test("Build phase uses 55/22/23 carbs/protein/fat split")
    func testMacroSplit_whenBuildPhase_uses55_22_23() {
        let athlete = makeAthlete(weightKg: 70)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .build,
            session: nil,
            preferences: .default
        )

        // Total 2100 cal
        // Carbs: (2100 * 0.55) / 4 = 288
        // Protein: (2100 * 0.22) / 4 = 115
        // Fat: (2100 * 0.23) / 9 = 53
        #expect(target.carbsGramsTarget == 288)
        #expect(target.proteinGramsTarget == 115)
        #expect(target.fatGramsTarget == 53)
    }

    // MARK: - Peak Phase Macro Split (60/18/22)

    @Test("Peak phase uses 60/18/22 carbs/protein/fat split with higher carbs")
    func testMacroSplit_whenPeakPhase_uses60_18_22() {
        let athlete = makeAthlete(weightKg: 70)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .peak,
            session: nil,
            preferences: .default
        )

        // Total 2100 cal
        // Carbs: (2100 * 0.60) / 4 = 315
        // Protein: (2100 * 0.18) / 4 = 94
        // Fat: (2100 * 0.22) / 9 = 51
        #expect(target.carbsGramsTarget == 315)
        #expect(target.proteinGramsTarget == 94)
        #expect(target.fatGramsTarget == 51)
    }

    // MARK: - Taper Phase Macro Split (50/22/28)

    @Test("Taper phase uses 50/22/28 carbs/protein/fat split")
    func testMacroSplit_whenTaperPhase_uses50_22_28() {
        let athlete = makeAthlete(weightKg: 70)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .taper,
            session: nil,
            preferences: .default
        )

        // Total 2100 cal
        // Carbs: (2100 * 0.50) / 4 = 262
        // Protein: (2100 * 0.22) / 4 = 115
        // Fat: (2100 * 0.28) / 9 = 65
        #expect(target.carbsGramsTarget == 262)
        #expect(target.proteinGramsTarget == 115)
        #expect(target.fatGramsTarget == 65)
    }

    // MARK: - Recovery Phase Macro Split (50/25/25)

    @Test("Recovery phase uses 50/25/25 carbs/protein/fat split with higher protein")
    func testMacroSplit_whenRecoveryPhase_uses50_25_25() {
        let athlete = makeAthlete(weightKg: 70)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .recovery,
            session: nil,
            preferences: .default
        )

        // Total 2100 cal
        // Carbs: (2100 * 0.50) / 4 = 262
        // Protein: (2100 * 0.25) / 4 = 131
        // Fat: (2100 * 0.25) / 9 = 58
        #expect(target.carbsGramsTarget == 262)
        #expect(target.proteinGramsTarget == 131)
        #expect(target.fatGramsTarget == 58)
    }

    // MARK: - Race Phase Macro Split (65/15/20)

    @Test("Race phase uses 65/15/20 carbs/protein/fat split with highest carbs")
    func testMacroSplit_whenRacePhase_uses65_15_20() {
        let athlete = makeAthlete(weightKg: 70)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .race,
            session: nil,
            preferences: .default
        )

        // Total 2100 cal
        // Carbs: (2100 * 0.65) / 4 = 341
        // Protein: (2100 * 0.15) / 4 = 78
        // Fat: (2100 * 0.20) / 9 = 46
        #expect(target.carbsGramsTarget == 341)
        #expect(target.proteinGramsTarget == 78)
        #expect(target.fatGramsTarget == 46)
    }

    // MARK: - Hydration Calculation

    @Test("Hydration on rest day equals 30 times weight")
    func testHydration_whenNoSession_equalsBaseHydration() {
        let athlete = makeAthlete(weightKg: 70)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            session: nil,
            preferences: .default
        )

        // 30 * 70 = 2100 + 0 session = 2100
        #expect(target.hydrationMlTarget == 2100)
    }

    @Test("Hydration with session adds 500ml per hour of activity")
    func testHydration_whenSession_addsSessionHours() {
        let athlete = makeAthlete(weightKg: 70)
        let session = makeSession(type: .longRun, durationHours: 3.0)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            session: session,
            preferences: .default
        )

        // 30 * 70 = 2100 + 3.0 * 500 = 1500 => 3600
        #expect(target.hydrationMlTarget == 3600)
    }

    @Test("Hydration with short session adds proportional amount")
    func testHydration_whenShortSession_addsProportionalAmount() {
        let athlete = makeAthlete(weightKg: 80)
        let session = makeSession(type: .recovery, durationHours: 0.5)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .recovery,
            session: session,
            preferences: .default
        )

        // 30 * 80 = 2400 + 0.5 * 500 = 250 => 2650
        #expect(target.hydrationMlTarget == 2650)
    }

    // MARK: - Target Metadata

    @Test("Target includes correct training phase")
    func testTarget_containsCorrectPhase() {
        let athlete = makeAthlete()
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .peak,
            session: nil,
            preferences: .default
        )

        #expect(target.trainingPhase == .peak)
    }

    @Test("Target includes session type when session provided")
    func testTarget_whenSessionProvided_containsSessionType() {
        let athlete = makeAthlete()
        let session = makeSession(type: .tempo)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .build,
            session: session,
            preferences: .default
        )

        #expect(target.sessionType == .tempo)
    }

    @Test("Target has nil session type when no session")
    func testTarget_whenNoSession_hasNilSessionType() {
        let athlete = makeAthlete()
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            session: nil,
            preferences: .default
        )

        #expect(target.sessionType == nil)
    }

    @Test("Target session advice is nil from calculator")
    func testTarget_sessionAdviceIsNil() {
        let athlete = makeAthlete()
        let session = makeSession(type: .longRun)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            session: session,
            preferences: .default
        )

        #expect(target.sessionAdvice == nil)
    }
}
