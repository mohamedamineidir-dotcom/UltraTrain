import Foundation

struct PerformanceTrend: Identifiable, Equatable, Sendable {
    let id: UUID
    var type: PerformanceTrendType
    var dataPoints: [TrendDataPoint]
    var trendDirection: PerformanceTrendDirection
    var changePercent: Double
    var summary: String
    var analyzedDate: Date

    var icon: String {
        switch type {
        case .aerobicEfficiency: return "lungs.fill"
        case .climbingEfficiency: return "mountain.2.fill"
        case .enduranceFade: return "battery.50percent"
        case .recoveryRate: return "heart.text.square.fill"
        }
    }

    var trendArrow: String {
        switch trendDirection {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    var displayName: String {
        switch type {
        case .aerobicEfficiency: return "Aerobic Efficiency"
        case .climbingEfficiency: return "Climbing Efficiency"
        case .enduranceFade: return "Endurance Fade"
        case .recoveryRate: return "Recovery Rate"
        }
    }
}
