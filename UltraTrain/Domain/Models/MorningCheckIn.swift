import Foundation

struct MorningCheckIn: Identifiable, Equatable, Sendable {
    let id: UUID
    var date: Date
    var perceivedEnergy: Int
    var muscleSoreness: Int
    var mood: Int
    var sleepQualitySubjective: Int
    var notes: String?
}
