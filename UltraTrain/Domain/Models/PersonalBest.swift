import Foundation

struct PersonalBest: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    let distance: PersonalBestDistance
    let timeSeconds: TimeInterval
    let date: Date

    var pacePerKm: TimeInterval {
        guard distance.distanceKm > 0 else { return 0 }
        return timeSeconds / distance.distanceKm
    }

    /// Exponential decay: halves every 180 days from the given reference date.
    func recencyWeight(relativeTo referenceDate: Date = .now) -> Double {
        let daysSince = referenceDate.timeIntervalSince(date) / 86400.0
        guard daysSince >= 0 else { return 1.0 }
        let halfLife = 180.0
        return pow(0.5, daysSince / halfLife)
    }
}

enum PersonalBestDistance: String, CaseIterable, Sendable, Codable {
    case fiveK = "5K"
    case tenK = "10K"
    case halfMarathon = "Half Marathon"
    case marathon = "Marathon"

    var distanceKm: Double {
        switch self {
        case .fiveK: 5.0
        case .tenK: 10.0
        case .halfMarathon: 21.0975
        case .marathon: 42.195
        }
    }

    var shortLabel: String {
        switch self {
        case .fiveK: "5K"
        case .tenK: "10K"
        case .halfMarathon: "Half"
        case .marathon: "Marathon"
        }
    }
}
