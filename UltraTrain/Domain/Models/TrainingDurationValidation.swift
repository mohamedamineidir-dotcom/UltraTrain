import Foundation

struct TrainingDurationValidation: Sendable {
    let isSufficient: Bool
    let availableWeeks: Int
    let minimumWeeks: Int
    let raceCategory: RaceCategory
    let warningMessage: String?
}
