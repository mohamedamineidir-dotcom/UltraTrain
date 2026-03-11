import Foundation
import Testing
@testable import UltraTrain

@Suite("Daily Nutrition Calculator Tests")
struct DailyNutritionCalculatorTests {

    // MARK: - Test Helpers

    private func makeAthlete(
        weightKg: Double = 70,
        heightCm: Double = 175,
        age: Int = 30,
        sex: BiologicalSex = .male,
        weightGoal: WeightGoal = .maintain
    ) -> Athlete {
        Athlete(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -age, to: .now)!,
            weightKg: weightKg,
            heightCm: heightCm,
            restingHeartRate: 55,
            maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 40,
            longestRunKm: 25,
            preferredUnit: .metric,
            weightGoal: weightGoal,
            biologicalSex: sex
        )
    }

    private func makeSession(
        type: SessionType,
        durationHours: Double = 1.0,
        distanceKm: Double = 10
    ) -> TrainingSession {
        TrainingSession(
            id: UUID(),
            date: Date.now,
            type: type,
            plannedDistanceKm: distanceKm,
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

    // MARK: - BMR Tests

    // Male BMR: 10×70 + 6.25×175 - 5×30 + 5 = 700 + 1093.75 - 150 + 5 = 1648.75
    // NEAT: 1648.75 × 1.4 = 2308.25 → Int = 2308

    @Test("BMR uses Mifflin-St Jeor for male")
    func testBMR_male() {
        let bmr = DailyNutritionCalculator.mifflinStJeorBMR(
            weightKg: 70, heightCm: 175, age: 30, sex: .male
        )
        #expect(abs(bmr - 1648.75) < 0.01)
    }

    @Test("BMR uses Mifflin-St Jeor for female")
    func testBMR_female() {
        // Female: 10×70 + 6.25×175 - 5×30 - 161 = 1482.75
        let bmr = DailyNutritionCalculator.mifflinStJeorBMR(
            weightKg: 70, heightCm: 175, age: 30, sex: .female
        )
        #expect(abs(bmr - 1482.75) < 0.01)
    }

    @Test("BMR never goes below 1200")
    func testBMR_safetyFloor() {
        let bmr = DailyNutritionCalculator.mifflinStJeorBMR(
            weightKg: 40, heightCm: 140, age: 80, sex: .female
        )
        #expect(bmr >= 1200)
    }

    // MARK: - Rest Week Calorie Calculation

    @Test("Rest week calories use NEAT only (no exercise)")
    func testRestWeek_equalsNEAT() {
        let athlete = makeAthlete(weightKg: 70)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            weeklySessions: [],
            todaySession: nil,
            preferences: .default
        )

        // BMR: 1648.75, NEAT: 2308.25, no exercise → 2308
        #expect(target.caloriesTarget == 2308)
    }

    @Test("Heavier athlete gets more calories")
    func testRestWeek_heavierAthlete_returnsHigherCalories() {
        let athlete = makeAthlete(weightKg: 85, heightCm: 185)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            weeklySessions: [],
            todaySession: nil,
            preferences: .default
        )

        // BMR: 10×85 + 6.25×185 - 5×30 + 5 = 850 + 1156.25 - 150 + 5 = 1861.25
        // NEAT: 1861.25 × 1.4 = 2605.75 → 2605
        #expect(target.caloriesTarget == 2605)
    }

    // MARK: - Weekly Average Exercise

    @Test("Weekly sessions are averaged across 7 days")
    func testCalories_weeklyAverage_spreadAcross7Days() {
        let athlete = makeAthlete(weightKg: 70)
        // One 20km long run
        let sessions = [makeSession(type: .longRun, durationHours: 3.0, distanceKm: 20)]
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            weeklySessions: sessions,
            todaySession: nil,
            preferences: .default
        )

        // Exercise: 70 × 20 × 1.0 = 1400 kcal / 7 = 200 kcal/day
        // NEAT: 2308.25 + 200 = 2508.25 → 2508
        #expect(target.caloriesTarget == 2508)
    }

    @Test("Same daily target whether it's rest day or training day")
    func testCalories_weeklyAverage_sameOnRestAndTrainingDay() {
        let athlete = makeAthlete(weightKg: 70)
        let sessions = [
            makeSession(type: .longRun, durationHours: 3.0, distanceKm: 20),
            makeSession(type: .tempo, durationHours: 1.0, distanceKm: 10)
        ]

        let targetOnRestDay = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            weeklySessions: sessions,
            todaySession: nil,
            preferences: .default
        )

        let targetOnTrainingDay = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            weeklySessions: sessions,
            todaySession: sessions[0],
            preferences: .default
        )

        #expect(targetOnRestDay.caloriesTarget == targetOnTrainingDay.caloriesTarget)
    }

    @Test("Multiple sessions sum their exercise calories")
    func testCalories_multipleSessions_summed() {
        let athlete = makeAthlete(weightKg: 70)
        let sessions = [
            makeSession(type: .longRun, durationHours: 3.0, distanceKm: 20),
            makeSession(type: .tempo, durationHours: 1.0, distanceKm: 10),
            makeSession(type: .recovery, durationHours: 0.75, distanceKm: 8)
        ]
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .build,
            weeklySessions: sessions,
            todaySession: nil,
            preferences: .default
        )

        // LongRun: 70 × 20 × 1.0 = 1400
        // Tempo: 70 × 10 × 1.15 = 805
        // Recovery: 70 × 8 × 0.85 = 476
        // Total weekly: 2681, daily avg: 383
        // NEAT: 2308.25 + 383 = 2691 → 2691
        #expect(target.caloriesTarget == 2691)
    }

    @Test("Rest session type adds zero exercise calories")
    func testCalories_restSession_addsZero() {
        let athlete = makeAthlete(weightKg: 70)
        let sessions = [makeSession(type: .rest, durationHours: 0, distanceKm: 0)]
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .recovery,
            weeklySessions: sessions,
            todaySession: nil,
            preferences: .default
        )

        #expect(target.caloriesTarget == 2308)
    }

    // MARK: - Weight Goal Adjustments

    @Test("Gain goal adds ~12% of TDEE")
    func testCalories_gainGoal_addsProportional() {
        let athlete = makeAthlete(weightKg: 70, weightGoal: .gain)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            weeklySessions: [],
            todaySession: nil,
            preferences: .default
        )

        // TDEE: 2308.25, +12% = +276 → 2584
        #expect(target.caloriesTarget == 2584)
    }

    @Test("Lose goal subtracts ~10% of TDEE")
    func testCalories_loseGoal_subtractsProportional() {
        let athlete = makeAthlete(weightKg: 70, weightGoal: .lose)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            weeklySessions: [],
            todaySession: nil,
            preferences: .default
        )

        // TDEE: 2308.25, -10% = -230 → 2078
        #expect(target.caloriesTarget == 2078)
    }

    // MARK: - Female BMR in Full Calculation

    @Test("Female athlete gets lower calories due to lower BMR")
    func testCalories_whenFemale_usesFemaleBMR() {
        let athlete = makeAthlete(weightKg: 70, sex: .female)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            weeklySessions: [],
            todaySession: nil,
            preferences: .default
        )

        // BMR: 1482.75, NEAT: 2075.85 → 2075
        #expect(target.caloriesTarget == 2075)
    }

    @Test("Tall athlete gets more calories")
    func testCalories_withTallAthlete_scalesWithHeight() {
        let athlete = makeAthlete(weightKg: 69, heightCm: 181)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            weeklySessions: [],
            todaySession: nil,
            preferences: .default
        )

        // BMR: 10×69 + 6.25×181 - 5×30 + 5 = 690 + 1131.25 - 150 + 5 = 1676.25
        // NEAT: 1676.25 × 1.4 = 2346.75 → 2346
        #expect(target.caloriesTarget == 2346)
    }

    // MARK: - User's Test Case (181cm/69kg male, gain, ~50km week)

    @Test("User test case: 181cm/69kg male wanting to gain with 50km week")
    func testUserTestCase_tallLightMaleGain50km() {
        let athlete = makeAthlete(
            weightKg: 69, heightCm: 181, age: 30, sex: .male, weightGoal: .gain
        )
        // Approximate a 50km week with mixed sessions
        let sessions = [
            makeSession(type: .longRun, durationHours: 3.5, distanceKm: 22),
            makeSession(type: .tempo, durationHours: 1.0, distanceKm: 10),
            makeSession(type: .recovery, durationHours: 0.75, distanceKm: 8),
            makeSession(type: .intervals, durationHours: 1.0, distanceKm: 10)
        ]
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .build,
            weeklySessions: sessions,
            todaySession: nil,
            preferences: .default
        )

        // LongRun: 69×22×1.0 = 1518
        // Tempo: 69×10×1.15 = 793.5
        // Recovery: 69×8×0.85 = 469.2
        // Intervals: 69×10×1.15 = 793.5
        // Weekly total: 3574.2, daily avg: 510.6
        // NEAT: 2346.75 + 510.6 = 2857.35
        // Gain (+12%): +342.88 → 3200
        #expect(target.caloriesTarget >= 3100)
        #expect(target.caloriesTarget <= 3300)
    }

    // MARK: - Phase Macro Splits

    @Test("Base phase uses 55/20/25 carbs/protein/fat split")
    func testMacroSplit_whenBasePhase_uses55_20_25() {
        let athlete = makeAthlete(weightKg: 70)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            weeklySessions: [],
            todaySession: nil,
            preferences: .default
        )

        // Total 2308 cal
        let cals = Double(target.caloriesTarget)
        #expect(target.carbsGramsTarget == Int((cals * 0.55) / 4))
        #expect(target.proteinGramsTarget == Int((cals * 0.20) / 4))
        #expect(target.fatGramsTarget == Int((cals * 0.25) / 9))
    }

    @Test("Build phase uses 55/22/23 carbs/protein/fat split")
    func testMacroSplit_whenBuildPhase_uses55_22_23() {
        let athlete = makeAthlete(weightKg: 70)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .build,
            weeklySessions: [],
            todaySession: nil,
            preferences: .default
        )

        let cals = Double(target.caloriesTarget)
        #expect(target.carbsGramsTarget == Int((cals * 0.55) / 4))
        #expect(target.proteinGramsTarget == Int((cals * 0.22) / 4))
        #expect(target.fatGramsTarget == Int((cals * 0.23) / 9))
    }

    @Test("Peak phase uses 60/18/22 carbs/protein/fat split")
    func testMacroSplit_whenPeakPhase_uses60_18_22() {
        let athlete = makeAthlete(weightKg: 70)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .peak,
            weeklySessions: [],
            todaySession: nil,
            preferences: .default
        )

        let cals = Double(target.caloriesTarget)
        #expect(target.carbsGramsTarget == Int((cals * 0.60) / 4))
        #expect(target.proteinGramsTarget == Int((cals * 0.18) / 4))
        #expect(target.fatGramsTarget == Int((cals * 0.22) / 9))
    }

    @Test("Taper phase uses 50/22/28 carbs/protein/fat split")
    func testMacroSplit_whenTaperPhase_uses50_22_28() {
        let athlete = makeAthlete(weightKg: 70)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .taper,
            weeklySessions: [],
            todaySession: nil,
            preferences: .default
        )

        let cals = Double(target.caloriesTarget)
        #expect(target.carbsGramsTarget == Int((cals * 0.50) / 4))
        #expect(target.proteinGramsTarget == Int((cals * 0.22) / 4))
        #expect(target.fatGramsTarget == Int((cals * 0.28) / 9))
    }

    @Test("Recovery phase uses 50/25/25 carbs/protein/fat split")
    func testMacroSplit_whenRecoveryPhase_uses50_25_25() {
        let athlete = makeAthlete(weightKg: 70)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .recovery,
            weeklySessions: [],
            todaySession: nil,
            preferences: .default
        )

        let cals = Double(target.caloriesTarget)
        #expect(target.carbsGramsTarget == Int((cals * 0.50) / 4))
        #expect(target.proteinGramsTarget == Int((cals * 0.25) / 4))
        #expect(target.fatGramsTarget == Int((cals * 0.25) / 9))
    }

    @Test("Race phase uses 65/15/20 carbs/protein/fat split")
    func testMacroSplit_whenRacePhase_uses65_15_20() {
        let athlete = makeAthlete(weightKg: 70)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .race,
            weeklySessions: [],
            todaySession: nil,
            preferences: .default
        )

        let cals = Double(target.caloriesTarget)
        #expect(target.carbsGramsTarget == Int((cals * 0.65) / 4))
        #expect(target.proteinGramsTarget == Int((cals * 0.15) / 4))
        #expect(target.fatGramsTarget == Int((cals * 0.20) / 9))
    }

    // MARK: - Hydration

    @Test("Hydration on rest week equals 30 times weight")
    func testHydration_whenNoSessions_equalsBaseHydration() {
        let athlete = makeAthlete(weightKg: 70)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            weeklySessions: [],
            todaySession: nil,
            preferences: .default
        )

        #expect(target.hydrationMlTarget == 2100)
    }

    @Test("Hydration with weekly sessions adds averaged session hours")
    func testHydration_whenWeeklySessions_addsAveragedHours() {
        let athlete = makeAthlete(weightKg: 70)
        // 7 hours total weekly → 1h/day average → +500ml/day
        let sessions = [
            makeSession(type: .longRun, durationHours: 3.0, distanceKm: 20),
            makeSession(type: .tempo, durationHours: 1.5, distanceKm: 12),
            makeSession(type: .recovery, durationHours: 1.0, distanceKm: 8),
            makeSession(type: .intervals, durationHours: 1.5, distanceKm: 12)
        ]
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            weeklySessions: sessions,
            todaySession: nil,
            preferences: .default
        )

        // Base: 30 × 70 = 2100, sessions: 7h total / 7 = 1h/day × 500 = 500 → 2600
        #expect(target.hydrationMlTarget == 2600)
    }

    // MARK: - Target Metadata

    @Test("Target includes correct training phase")
    func testTarget_containsCorrectPhase() {
        let athlete = makeAthlete()
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .peak,
            weeklySessions: [],
            todaySession: nil,
            preferences: .default
        )

        #expect(target.trainingPhase == .peak)
    }

    @Test("Target includes session type when today session provided")
    func testTarget_whenTodaySessionProvided_containsSessionType() {
        let athlete = makeAthlete()
        let session = makeSession(type: .tempo)
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .build,
            weeklySessions: [session],
            todaySession: session,
            preferences: .default
        )

        #expect(target.sessionType == .tempo)
    }

    @Test("Target has nil session type when no today session")
    func testTarget_whenNoTodaySession_hasNilSessionType() {
        let athlete = makeAthlete()
        let target = DailyNutritionCalculator.calculateTarget(
            athlete: athlete,
            trainingPhase: .base,
            weeklySessions: [],
            todaySession: nil,
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
            weeklySessions: [session],
            todaySession: session,
            preferences: .default
        )

        #expect(target.sessionAdvice == nil)
    }

    // MARK: - Weekly Exercise Calories

    @Test("Weekly exercise calories uses distance-based formula")
    func testWeeklyExerciseCalories_distanceBased() {
        let sessions = [
            makeSession(type: .longRun, durationHours: 3.0, distanceKm: 20)
        ]
        let cals = DailyNutritionCalculator.weeklyExerciseCalories(
            sessions: sessions, weightKg: 70
        )
        // 70 × 20 × 1.0 = 1400
        #expect(abs(cals - 1400) < 0.01)
    }

    @Test("Weekly exercise calories falls back to duration when no distance")
    func testWeeklyExerciseCalories_durationFallback() {
        let sessions = [
            makeSession(type: .longRun, durationHours: 2.0, distanceKm: 0)
        ]
        let cals = DailyNutritionCalculator.weeklyExerciseCalories(
            sessions: sessions, weightKg: 70
        )
        // 70 × 2.0 × 7.5 = 1050
        #expect(abs(cals - 1050) < 0.01)
    }
}
