import Foundation

struct IntervalPhaseTransition: Equatable, Sendable {
    let fromPhase: IntervalPhaseType
    let toPhase: IntervalPhaseType
    let message: String
    let intervalNumber: Int?
    let totalIntervals: Int?
}
