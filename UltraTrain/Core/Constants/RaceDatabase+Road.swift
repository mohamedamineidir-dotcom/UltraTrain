import Foundation

// swiftlint:disable:next identifier_name
private func _d(_ year: Int, _ month: Int, _ day: Int) -> Date {
    DateComponents(calendar: .current, year: year, month: month, day: day).date!
}

// MARK: - Road Races

extension RaceDatabase {

    static let roadRaces: [KnownRace] = marathonMajors + otherMarathons + frenchRoad + halfMarathons + tenKRaces

    // MARK: Marathon Majors

    private static let marathonMajors: [KnownRace] = [
        KnownRace(name: "Boston Marathon", shortName: nil,
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "USA",
                  nextEditionDate: _d(2026, 4, 20), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "New York City Marathon", shortName: "NYC Marathon",
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "USA",
                  nextEditionDate: _d(2026, 11, 1), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Chicago Marathon", shortName: nil,
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "USA",
                  nextEditionDate: _d(2026, 10, 11), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "London Marathon", shortName: nil,
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "UK",
                  nextEditionDate: _d(2026, 4, 26), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Berlin Marathon", shortName: nil,
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "Germany",
                  nextEditionDate: _d(2026, 9, 27), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Tokyo Marathon", shortName: nil,
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "Japan",
                  nextEditionDate: _d(2027, 3, 7), terrainDifficulty: .easy, raceType: .road),
    ]

    // MARK: Other Marathons

    private static let otherMarathons: [KnownRace] = [
        KnownRace(name: "Marathon de Paris", shortName: "Paris Marathon",
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "France",
                  nextEditionDate: _d(2026, 4, 5), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Rotterdam Marathon", shortName: nil,
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "Netherlands",
                  nextEditionDate: _d(2026, 4, 12), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Valencia Marathon", shortName: nil,
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "Spain",
                  nextEditionDate: _d(2026, 12, 6), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Barcelona Marathon", shortName: nil,
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "Spain",
                  nextEditionDate: _d(2026, 3, 15), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Osaka Women's Marathon", shortName: nil,
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "Japan",
                  nextEditionDate: _d(2027, 1, 31), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Seoul Marathon", shortName: nil,
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "South Korea",
                  nextEditionDate: _d(2026, 3, 15), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Melbourne Marathon", shortName: nil,
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "Australia",
                  nextEditionDate: _d(2026, 10, 11), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Toronto Waterfront Marathon", shortName: nil,
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "Canada",
                  nextEditionDate: _d(2026, 10, 18), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Los Angeles Marathon", shortName: "LA Marathon",
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "USA",
                  nextEditionDate: _d(2026, 3, 8), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Marine Corps Marathon", shortName: nil,
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "USA",
                  nextEditionDate: _d(2026, 10, 25), terrainDifficulty: .easy, raceType: .road),
    ]

    // MARK: French Road Races

    private static let frenchRoad: [KnownRace] = [
        KnownRace(name: "Marathon du Medoc", shortName: nil,
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "France",
                  nextEditionDate: _d(2026, 9, 12), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Marseille-Cassis", shortName: nil,
                  distanceKm: 20.0, elevationGainM: 0, elevationLossM: 0, country: "France",
                  nextEditionDate: _d(2026, 10, 25), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "20km de Paris", shortName: nil,
                  distanceKm: 20.0, elevationGainM: 0, elevationLossM: 0, country: "France",
                  nextEditionDate: _d(2026, 10, 11), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Semi de Paris", shortName: "Paris Half Marathon",
                  distanceKm: 21.1, elevationGainM: 0, elevationLossM: 0, country: "France",
                  nextEditionDate: _d(2026, 3, 1), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Nice-Cannes Marathon", shortName: nil,
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "France",
                  nextEditionDate: _d(2026, 11, 8), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Marathon de Lyon", shortName: nil,
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "France",
                  nextEditionDate: _d(2026, 10, 4), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Marathon de Bordeaux", shortName: nil,
                  distanceKm: 42.195, elevationGainM: 0, elevationLossM: 0, country: "France",
                  nextEditionDate: _d(2026, 4, 19), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Corrida de Houilles", shortName: nil,
                  distanceKm: 10.0, elevationGainM: 0, elevationLossM: 0, country: "France",
                  nextEditionDate: _d(2026, 12, 13), terrainDifficulty: .easy, raceType: .road),
    ]

    // MARK: Half Marathons

    private static let halfMarathons: [KnownRace] = [
        KnownRace(name: "NYC Half Marathon", shortName: "NYC Half",
                  distanceKm: 21.1, elevationGainM: 0, elevationLossM: 0, country: "USA",
                  nextEditionDate: _d(2026, 3, 15), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "London Big Half", shortName: nil,
                  distanceKm: 21.1, elevationGainM: 0, elevationLossM: 0, country: "UK",
                  nextEditionDate: _d(2026, 9, 6), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Berlin Half Marathon", shortName: nil,
                  distanceKm: 21.1, elevationGainM: 0, elevationLossM: 0, country: "Germany",
                  nextEditionDate: _d(2026, 4, 5), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Great North Run", shortName: nil,
                  distanceKm: 21.1, elevationGainM: 0, elevationLossM: 0, country: "UK",
                  nextEditionDate: _d(2026, 9, 13), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Rock'n'Roll Las Vegas", shortName: nil,
                  distanceKm: 21.1, elevationGainM: 0, elevationLossM: 0, country: "USA",
                  nextEditionDate: _d(2026, 2, 22), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Lisbon Half Marathon", shortName: nil,
                  distanceKm: 21.1, elevationGainM: 0, elevationLossM: 0, country: "Portugal",
                  nextEditionDate: _d(2026, 3, 22), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Copenhagen Half Marathon", shortName: nil,
                  distanceKm: 21.1, elevationGainM: 0, elevationLossM: 0, country: "Denmark",
                  nextEditionDate: _d(2026, 9, 20), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Semi de Boulogne-Billancourt", shortName: "Semi de Boulogne",
                  distanceKm: 21.1, elevationGainM: 0, elevationLossM: 0, country: "France",
                  nextEditionDate: _d(2026, 11, 22), terrainDifficulty: .easy, raceType: .road),
    ]

    // MARK: 10K Races

    private static let tenKRaces: [KnownRace] = [
        KnownRace(name: "10km de Paris", shortName: "Paris 10K",
                  distanceKm: 10.0, elevationGainM: 0, elevationLossM: 0, country: "France",
                  nextEditionDate: _d(2026, 6, 7), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "NYC 10K", shortName: nil,
                  distanceKm: 10.0, elevationGainM: 0, elevationLossM: 0, country: "USA",
                  terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "London 10K", shortName: nil,
                  distanceKm: 10.0, elevationGainM: 0, elevationLossM: 0, country: "UK",
                  nextEditionDate: _d(2026, 7, 12), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Berlin 10K", shortName: nil,
                  distanceKm: 10.0, elevationGainM: 0, elevationLossM: 0, country: "Germany",
                  terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "AJC Peachtree Road Race", shortName: "Peachtree 10K",
                  distanceKm: 10.0, elevationGainM: 0, elevationLossM: 0, country: "USA",
                  nextEditionDate: _d(2026, 7, 4), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Cooper River Bridge Run", shortName: "Bridge Run 10K",
                  distanceKm: 10.0, elevationGainM: 0, elevationLossM: 0, country: "USA",
                  nextEditionDate: _d(2026, 4, 4), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Bolder Boulder", shortName: nil,
                  distanceKm: 10.0, elevationGainM: 0, elevationLossM: 0, country: "USA",
                  nextEditionDate: _d(2026, 5, 25), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Bay to Breakers", shortName: nil,
                  distanceKm: 12.0, elevationGainM: 0, elevationLossM: 0, country: "USA",
                  nextEditionDate: _d(2026, 5, 17), terrainDifficulty: .easy, raceType: .road),
    ]
}
