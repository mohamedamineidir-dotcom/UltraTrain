import Foundation

enum DailyNutritionCalculator {

    // MARK: - Phase Macro Splits

    private struct MacroSplit {
        let carbsPercent: Double
        let proteinPercent: Double
        let fatPercent: Double
    }

    private static func macroSplit(for phase: TrainingPhase) -> MacroSplit {
        switch phase {
        case .base:
            return MacroSplit(carbsPercent: 0.55, proteinPercent: 0.20, fatPercent: 0.25)
        case .build:
            return MacroSplit(carbsPercent: 0.55, proteinPercent: 0.22, fatPercent: 0.23)
        case .peak:
            return MacroSplit(carbsPercent: 0.60, proteinPercent: 0.18, fatPercent: 0.22)
        case .taper:
            return MacroSplit(carbsPercent: 0.50, proteinPercent: 0.22, fatPercent: 0.28)
        case .race:
            return MacroSplit(carbsPercent: 0.65, proteinPercent: 0.15, fatPercent: 0.20)
        case .recovery:
            return MacroSplit(carbsPercent: 0.50, proteinPercent: 0.25, fatPercent: 0.25)
        }
    }

    // MARK: - BMR (Mifflin-St Jeor)

    /// Calculates Basal Metabolic Rate using the Mifflin-St Jeor equation.
    /// Male:   10 × weight(kg) + 6.25 × height(cm) - 5 × age - 5 + 10 → simplified to +5
    /// Female: 10 × weight(kg) + 6.25 × height(cm) - 5 × age - 161
    static func mifflinStJeorBMR(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        sex: BiologicalSex
    ) -> Double {
        let base = 10.0 * weightKg + 6.25 * heightCm - 5.0 * Double(age)
        let bmr = switch sex {
        case .male: base + 5.0
        case .female: base - 161.0
        }
        return max(bmr, 1200) // safety floor
    }

    // MARK: - Weekly Exercise Calories

    private static func intensityFactor(for type: SessionType) -> Double {
        switch type {
        case .rest, .crossTraining: 0
        case .recovery: 0.85
        case .longRun, .backToBack: 1.0
        case .tempo, .intervals: 1.15
        case .verticalGain: 1.25
        case .strengthConditioning: 0.6
        case .race: 1.1
        }
    }

    /// Duration-based fallback rate (kcal per kg per hour) when distance is unavailable.
    private static func durationRate(for type: SessionType) -> Double {
        switch type {
        case .rest, .crossTraining: 0
        case .recovery: 4.5
        case .longRun, .backToBack: 7.5
        case .tempo, .intervals: 9.0
        case .verticalGain: 8.5
        case .strengthConditioning: 4.0
        case .race: 8.0
        }
    }

    private static func sessionCalories(
        for session: TrainingSession,
        weightKg: Double
    ) -> Double {
        let type = session.type
        guard type != .rest, type != .crossTraining else { return 0 }

        if session.plannedDistanceKm > 0 {
            // ~1 kcal/kg/km × intensity factor
            return weightKg * session.plannedDistanceKm * intensityFactor(for: type)
        } else {
            // Fallback: duration-based
            let hours = session.plannedDuration / 3600.0
            return weightKg * hours * durationRate(for: type)
        }
    }

    static func weeklyExerciseCalories(
        sessions: [TrainingSession],
        weightKg: Double
    ) -> Double {
        sessions.reduce(0) { $0 + sessionCalories(for: $1, weightKg: weightKg) }
    }

    // MARK: - Weight Goal Adjustment

    private static func goalAdjustmentFraction(for goal: WeightGoal) -> Double {
        switch goal {
        case .gain: 0.12
        case .maintain: 0
        case .lose: -0.10
        }
    }

    // MARK: - Public API

    /// Calculates a daily nutrition target as a **weekly average**.
    /// The same calorie number is shown every day of the week,
    /// making it easier for athletes to follow consistently.
    static func calculateTarget(
        athlete: Athlete,
        trainingPhase: TrainingPhase,
        weeklySessions: [TrainingSession],
        todaySession: TrainingSession?,
        preferences: NutritionPreferences
    ) -> DailyNutritionTarget {
        // 1. BMR
        let bmr = mifflinStJeorBMR(
            weightKg: athlete.weightKg,
            heightCm: athlete.heightCm,
            age: athlete.age,
            sex: athlete.biologicalSex
        )

        // 2. NEAT (lightly active baseline)
        let neat = bmr * 1.4

        // 3. Weekly exercise → daily average
        let weeklyExercise = weeklyExerciseCalories(
            sessions: weeklySessions,
            weightKg: athlete.weightKg
        )
        let dailyExercise = weeklyExercise / 7.0

        // 4. TDEE
        let tdee = neat + dailyExercise

        // 5. Weight goal adjustment (proportional to TDEE)
        let fraction = goalAdjustmentFraction(for: athlete.weightGoal)
        let goalAdjustment = Int(tdee * fraction)

        // 6. Final (never below BMR)
        let totalCalories = max(Int(tdee) + goalAdjustment, Int(bmr))

        // Macros
        let split = macroSplit(for: trainingPhase)
        let carbsGrams = Int((Double(totalCalories) * split.carbsPercent) / 4)
        let proteinGrams = Int((Double(totalCalories) * split.proteinPercent) / 4)
        let fatGrams = Int((Double(totalCalories) * split.fatPercent) / 9)

        // Hydration: base + average daily session contribution
        let weeklySessionHours = weeklySessions.reduce(0.0) { $0 + $1.plannedDuration / 3600.0 }
        let dailySessionHours = weeklySessionHours / 7.0
        let hydrationMl = Int(30 * athlete.weightKg) + Int(dailySessionHours * 500)

        return DailyNutritionTarget(
            date: todaySession?.date ?? Date.now,
            caloriesTarget: totalCalories,
            carbsGramsTarget: carbsGrams,
            proteinGramsTarget: proteinGrams,
            fatGramsTarget: fatGrams,
            hydrationMlTarget: hydrationMl,
            trainingPhase: trainingPhase,
            sessionType: todaySession?.type,
            sessionAdvice: nil
        )
    }
}
