import Foundation

struct FitnessProjectionPoint: Identifiable, Equatable, Sendable {
    let id: UUID
    var date: Date
    var projectedFitness: Double
    var projectedFatigue: Double
    var projectedForm: Double
}
