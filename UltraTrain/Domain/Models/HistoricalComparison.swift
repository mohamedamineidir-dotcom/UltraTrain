import Foundation

struct HistoricalComparison: Equatable, Sendable {
    var splitPRs: [SplitPR]
    var paceTrend: PaceTrend
    var badges: [ImprovementBadge]
}
