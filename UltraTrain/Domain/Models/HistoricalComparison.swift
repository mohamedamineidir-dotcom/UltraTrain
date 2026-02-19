import Foundation

struct HistoricalComparison: Equatable, Sendable {
    var splitPRs: [SplitPR]
    var paceTrend: PaceTrend
    var badges: [ImprovementBadge]
}

struct SplitPR: Identifiable, Equatable, Sendable {
    let id: UUID
    var kilometerNumber: Int
    var currentPace: Double
    var previousBestPace: Double
}

enum PaceTrend: String, Sendable {
    case improving
    case declining
    case stable
}

struct ImprovementBadge: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var description: String
    var icon: String
}
