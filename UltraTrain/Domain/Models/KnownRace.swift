import Foundation

struct KnownRace: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let shortName: String?
    let distanceKm: Double
    let elevationGainM: Double
    let elevationLossM: Double
    let country: String
    let nextEditionDate: Date?
    let terrainDifficulty: TerrainDifficulty
    let raceType: RaceType
    /// Highest point on the course in meters. Optional, when present
    /// and ≥ 2500m, the plan surfaces altitude-acclimatization advice
    /// in build/peak phases.
    let maxElevationM: Double?
    /// Whether trekking poles are allowed. Optional, when true, the
    /// plan surfaces a pole-training cue. Nil = unknown / unspecified.
    let polesAllowed: Bool?

    init(
        name: String,
        shortName: String? = nil,
        distanceKm: Double,
        elevationGainM: Double,
        elevationLossM: Double,
        country: String,
        nextEditionDate: Date? = nil,
        terrainDifficulty: TerrainDifficulty,
        raceType: RaceType = .trail,
        maxElevationM: Double? = nil,
        polesAllowed: Bool? = nil
    ) {
        self.name = name
        self.shortName = shortName
        self.distanceKm = distanceKm
        self.elevationGainM = elevationGainM
        self.elevationLossM = elevationLossM
        self.country = country
        self.nextEditionDate = nextEditionDate
        self.terrainDifficulty = terrainDifficulty
        self.raceType = raceType
        self.maxElevationM = maxElevationM
        self.polesAllowed = polesAllowed
    }
}
