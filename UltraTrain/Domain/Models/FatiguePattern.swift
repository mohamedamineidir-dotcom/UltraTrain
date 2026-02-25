import Foundation

struct FatiguePattern: Identifiable, Equatable, Sendable {
    let id: UUID
    var type: FatiguePatternType
    var severity: FatigueSeverity
    var evidence: [FatigueEvidence]
    var recommendation: String
    var suggestedDeloadDays: Int?
    var detectedDate: Date

    var icon: String {
        switch type {
        case .paceDecline: return "figure.run"
        case .heartRateDrift: return "heart.fill"
        case .sleepQualityDecline: return "moon.zzz.fill"
        case .rpeTrend: return "gauge.with.dots.needle.33percent"
        case .compoundFatigue: return "exclamationmark.triangle.fill"
        }
    }

    var severityColor: String {
        switch severity {
        case .mild: return "yellow"
        case .moderate: return "orange"
        case .significant: return "red"
        }
    }
}
