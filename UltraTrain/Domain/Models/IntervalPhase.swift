import Foundation

struct IntervalPhase: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    var phaseType: IntervalPhaseType
    var trigger: IntervalTrigger
    var targetIntensity: Intensity
    var repeatCount: Int
    var notes: String?

    var totalDuration: TimeInterval {
        switch trigger {
        case .duration(let seconds): return seconds * Double(repeatCount)
        case .distance: return 0
        }
    }
}
