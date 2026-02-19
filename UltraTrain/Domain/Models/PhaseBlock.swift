import Foundation

struct PhaseBlock: Identifiable, Equatable, Sendable {
    let id: UUID
    var phase: TrainingPhase
    var startDate: Date
    var endDate: Date
    var weekNumbers: [Int]
    var isCurrentPhase: Bool
}
