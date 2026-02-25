import Foundation

struct SessionNutritionAdvice: Equatable, Sendable {
    let preRun: PreRunAdvice?
    let duringRun: DuringRunAdvice?
    let postRun: PostRunAdvice
    let isGutTrainingRecommended: Bool
}
