import Foundation

struct GearItem: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var brand: String
    var type: GearType
    var purchaseDate: Date
    var maxDistanceKm: Double
    var totalDistanceKm: Double
    var totalDuration: TimeInterval
    var isRetired: Bool
    var notes: String?

    var usagePercentage: Double {
        guard maxDistanceKm > 0 else { return 0 }
        return min(totalDistanceKm / maxDistanceKm, 1.0)
    }

    var needsReplacement: Bool {
        maxDistanceKm > 0 && totalDistanceKm >= maxDistanceKm
    }

    var remainingKm: Double {
        max(0, maxDistanceKm - totalDistanceKm)
    }
}
