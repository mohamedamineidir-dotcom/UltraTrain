import Foundation

struct TrailPersonalBest: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    let distanceKm: Double
    let elevationGainM: Double
    let timeSeconds: TimeInterval
    let date: Date

    var effectiveDistanceKm: Double {
        distanceKm + elevationGainM / 100.0
    }

    var pacePerKm: TimeInterval {
        guard distanceKm > 0 else { return 0 }
        return timeSeconds / distanceKm
    }

    var pacePerEffectiveKm: TimeInterval {
        guard effectiveDistanceKm > 0 else { return 0 }
        return timeSeconds / effectiveDistanceKm
    }

    /// Exponential decay: halves every 180 days from the given reference date.
    func recencyWeight(relativeTo referenceDate: Date = .now) -> Double {
        let daysSince = referenceDate.timeIntervalSince(date) / 86400.0
        guard daysSince >= 0 else { return 1.0 }
        let halfLife = 180.0
        return pow(0.5, daysSince / halfLife)
    }

    var formattedDistance: String {
        if distanceKm >= 100 {
            return String(format: "%.0f km", distanceKm)
        }
        return String(format: "%.1f km", distanceKm)
    }

    var formattedElevation: String {
        String(format: "%.0f m D+", elevationGainM)
    }
}
