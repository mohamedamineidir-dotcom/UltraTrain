import Foundation

struct RaceReadinessForecast: Equatable, Sendable {
    var raceName: String
    var raceDate: Date
    var daysUntilRace: Int
    var currentFitness: Double
    var projectedFitnessAtRace: Double
    var projectedFormAtRace: Double
    var projectedFormStatus: FormStatus
    var fitnessProjectionPoints: [FitnessProjectionPoint]
}

struct FitnessProjectionPoint: Identifiable, Equatable, Sendable {
    let id: UUID
    var date: Date
    var projectedFitness: Double
    var projectedFatigue: Double
    var projectedForm: Double
}
