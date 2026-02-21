import Foundation

enum FatiguePatternType: String, Sendable, CaseIterable {
    case paceDecline
    case heartRateDrift
    case sleepQualityDecline
    case rpeTrend
    case compoundFatigue
}

enum FatigueSeverity: String, Sendable, CaseIterable {
    case mild
    case moderate
    case significant
}

struct FatigueEvidence: Equatable, Sendable {
    var metric: String
    var baselineValue: Double
    var currentValue: Double
    var changePercent: Double
    var period: String
}

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
