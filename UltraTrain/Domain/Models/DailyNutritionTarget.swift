import Foundation

struct DailyNutritionTarget: Equatable, Sendable {
    let date: Date
    var caloriesTarget: Int
    var carbsGramsTarget: Int
    var proteinGramsTarget: Int
    var fatGramsTarget: Int
    var hydrationMlTarget: Int
    var trainingPhase: TrainingPhase
    var sessionType: SessionType?
    var sessionAdvice: SessionNutritionAdvice?

    var carbsPercentage: Double {
        let totalCalories = Double(caloriesTarget)
        guard totalCalories > 0 else { return 0 }
        return (Double(carbsGramsTarget) * 4) / totalCalories * 100
    }

    var proteinPercentage: Double {
        let totalCalories = Double(caloriesTarget)
        guard totalCalories > 0 else { return 0 }
        return (Double(proteinGramsTarget) * 4) / totalCalories * 100
    }

    var fatPercentage: Double {
        let totalCalories = Double(caloriesTarget)
        guard totalCalories > 0 else { return 0 }
        return (Double(fatGramsTarget) * 9) / totalCalories * 100
    }
}
