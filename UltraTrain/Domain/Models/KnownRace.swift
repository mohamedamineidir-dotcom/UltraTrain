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

    init(
        name: String,
        shortName: String? = nil,
        distanceKm: Double,
        elevationGainM: Double,
        elevationLossM: Double,
        country: String,
        nextEditionDate: Date? = nil,
        terrainDifficulty: TerrainDifficulty,
        raceType: RaceType = .trail
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
    }
}
