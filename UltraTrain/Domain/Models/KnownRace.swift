import Foundation

struct KnownRace: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let shortName: String?
    let distanceKm: Double
    let elevationGainM: Double
    let elevationLossM: Double
    let country: String
}
