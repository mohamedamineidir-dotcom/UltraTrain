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

    // MARK: - Activity Calorie Addition

    private static func activityCalories(for session: TrainingSession?) -> Int {
        guard let session else { return 0 }
        let durationHours = session.plannedDuration / 3600.0

        switch session.type {
        case .rest, .crossTraining:
            return 0
        case .recovery:
            return Int(durationHours * 300)
        case .tempo, .intervals:
            return Int(durationHours * 600)
        case .longRun, .backToBack:
            return Int(durationHours * 500)
        case .verticalGain:
            return Int(durationHours * 550)
        }
    }

    // MARK: - Public API

    static func calculateTarget(
        athlete: Athlete,
        trainingPhase: TrainingPhase,
        session: TrainingSession?,
        preferences: NutritionPreferences
    ) -> DailyNutritionTarget {
        let baseCalories = Int(athlete.weightKg * 30)
        let activity = activityCalories(for: session)
        let totalCalories = baseCalories + activity

        let split = macroSplit(for: trainingPhase)

        let carbsGrams = Int((Double(totalCalories) * split.carbsPercent) / 4)
        let proteinGrams = Int((Double(totalCalories) * split.proteinPercent) / 4)
        let fatGrams = Int((Double(totalCalories) * split.fatPercent) / 9)

        let sessionDurationHours = (session?.plannedDuration ?? 0) / 3600.0
        let hydrationMl = Int(30 * athlete.weightKg) + Int(sessionDurationHours * 500)

        return DailyNutritionTarget(
            date: session?.date ?? Date.now,
            caloriesTarget: totalCalories,
            carbsGramsTarget: carbsGrams,
            proteinGramsTarget: proteinGrams,
            fatGramsTarget: fatGrams,
            hydrationMlTarget: hydrationMl,
            trainingPhase: trainingPhase,
            sessionType: session?.type,
            sessionAdvice: nil
        )
    }
}
