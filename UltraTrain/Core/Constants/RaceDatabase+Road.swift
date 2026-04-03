import Foundation

// swiftlint:disable:next identifier_name
private func _d(_ year: Int, _ month: Int, _ day: Int) -> Date {
    DateComponents(calendar: .current, year: year, month: month, day: day).date!
}

// MARK: - Road Races

extension RaceDatabase {

    static let roadRaces: [KnownRace] =
        marathonMajors + internationalMarathons + internationalHalfs + internationalTenK
        + frenchRoadRaces + usaRoadRaces

    // MARK: World Marathon Majors

    private static let marathonMajors: [KnownRace] = [
        KnownRace(name: "Boston Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 248, elevationLossM: 388,
                  country: "USA", nextEditionDate: _d(2026, 4, 20), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "New York City Marathon", shortName: "NYC Marathon", distanceKm: 42.195, elevationGainM: 247,
                  elevationLossM: 251, country: "USA", nextEditionDate: _d(2026, 11, 1), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Chicago Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 74, elevationLossM: 73,
                  country: "USA", nextEditionDate: _d(2026, 10, 11), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "London Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 127, elevationLossM: 161,
                  country: "UK", nextEditionDate: _d(2026, 4, 26), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Berlin Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 73, elevationLossM: 79,
                  country: "Germany", nextEditionDate: _d(2026, 9, 27), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Tokyo Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 40, elevationLossM: 40,
                  country: "Japan", nextEditionDate: _d(2027, 3, 7), terrainDifficulty: .easy, raceType: .road),
    ]

    // MARK: International Marathons (non-US, non-France)

    // swiftlint:disable:next function_body_length
    private static let internationalMarathons: [KnownRace] = [
        // Europe
        KnownRace(name: "Rotterdam Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 10, elevationLossM: 10,
                  country: "Netherlands", nextEditionDate: _d(2026, 4, 12), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Valencia Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 20, elevationLossM: 20,
                  country: "Spain", nextEditionDate: _d(2026, 12, 6), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Barcelona Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 60, elevationLossM: 60,
                  country: "Spain", nextEditionDate: _d(2026, 3, 15), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Amsterdam Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 10, elevationLossM: 10,
                  country: "Netherlands", nextEditionDate: _d(2026, 10, 18), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Vienna Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 40, elevationLossM: 40,
                  country: "Austria", nextEditionDate: _d(2026, 4, 19), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Dublin Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 50, elevationLossM: 50,
                  country: "Ireland", nextEditionDate: _d(2026, 10, 25), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Stockholm Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 60, elevationLossM: 60,
                  country: "Sweden", nextEditionDate: _d(2026, 6, 6), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Prague Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 40, elevationLossM: 40,
                  country: "Czech Republic", nextEditionDate: _d(2026, 5, 3), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Zurich Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 50, elevationLossM: 50,
                  country: "Switzerland", nextEditionDate: _d(2026, 4, 19), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Athens Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 250, elevationLossM: 250,
                  country: "Greece", nextEditionDate: _d(2026, 11, 8), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Seville Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 10, elevationLossM: 10,
                  country: "Spain", nextEditionDate: _d(2026, 2, 15), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Rome Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 40, elevationLossM: 40,
                  country: "Italy", nextEditionDate: _d(2026, 3, 22), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Florence Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 30, elevationLossM: 30,
                  country: "Italy", nextEditionDate: _d(2026, 11, 29), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Milan Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 20, elevationLossM: 20,
                  country: "Italy", nextEditionDate: _d(2026, 4, 5), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Lisbon Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 60, elevationLossM: 60,
                  country: "Portugal", nextEditionDate: _d(2026, 10, 18), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Istanbul Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 80, elevationLossM: 80,
                  country: "Turkey", nextEditionDate: _d(2026, 11, 1), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Hamburg Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 20, elevationLossM: 20,
                  country: "Germany", nextEditionDate: _d(2026, 4, 26), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Hannover Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 30, elevationLossM: 30,
                  country: "Germany", nextEditionDate: _d(2026, 4, 26), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Edinburgh Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 70, elevationLossM: 70,
                  country: "UK", nextEditionDate: _d(2026, 5, 24), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Manchester Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 30, elevationLossM: 30,
                  country: "UK", nextEditionDate: _d(2026, 4, 19), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Liverpool Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 30, elevationLossM: 30,
                  country: "UK", nextEditionDate: _d(2026, 10, 25), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Copenhagen Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 10, elevationLossM: 10,
                  country: "Denmark", nextEditionDate: _d(2026, 5, 17), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Warsaw Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 30, elevationLossM: 30,
                  country: "Poland", nextEditionDate: _d(2026, 9, 27), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Budapest Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 40, elevationLossM: 40,
                  country: "Hungary", nextEditionDate: _d(2026, 10, 11), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Eindhoven Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 10, elevationLossM: 10,
                  country: "Netherlands", nextEditionDate: _d(2026, 10, 11), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Geneva Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 40, elevationLossM: 40,
                  country: "Switzerland", nextEditionDate: _d(2026, 5, 10), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Midnight Sun Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 100, elevationLossM: 100,
                  country: "Norway", nextEditionDate: _d(2026, 6, 20), terrainDifficulty: .easy, raceType: .road),
        // Asia
        KnownRace(name: "Seoul Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 60, elevationLossM: 60,
                  country: "South Korea", nextEditionDate: _d(2026, 3, 15), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Osaka Women's Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 20, elevationLossM: 20,
                  country: "Japan", nextEditionDate: _d(2027, 1, 25), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Nagoya Women's Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 20, elevationLossM: 20,
                  country: "Japan", nextEditionDate: _d(2026, 3, 8), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Fukuoka Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 30, elevationLossM: 30,
                  country: "Japan", nextEditionDate: _d(2026, 12, 6), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Singapore Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 20, elevationLossM: 20,
                  country: "Singapore", nextEditionDate: _d(2026, 12, 6), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Mumbai Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 20, elevationLossM: 20,
                  country: "India", nextEditionDate: _d(2026, 1, 18), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Shanghai Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 10, elevationLossM: 10,
                  country: "China", nextEditionDate: _d(2026, 11, 29), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Taipei Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 20, elevationLossM: 20,
                  country: "Taiwan", nextEditionDate: _d(2026, 12, 20), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Bangkok Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 10, elevationLossM: 10,
                  country: "Thailand", nextEditionDate: _d(2026, 2, 1), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Ho Chi Minh City Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 10, elevationLossM: 10,
                  country: "Vietnam", nextEditionDate: _d(2026, 1, 11), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Dubai Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 5, elevationLossM: 5,
                  country: "UAE", nextEditionDate: _d(2026, 1, 9), terrainDifficulty: .easy, raceType: .road),
        // Oceania
        KnownRace(name: "Melbourne Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 30, elevationLossM: 30,
                  country: "Australia", nextEditionDate: _d(2026, 10, 11), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Gold Coast Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 10, elevationLossM: 10,
                  country: "Australia", nextEditionDate: _d(2026, 7, 4), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Sydney Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 80, elevationLossM: 80,
                  country: "Australia", nextEditionDate: _d(2026, 9, 20), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Queenstown Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 60, elevationLossM: 60,
                  country: "New Zealand", nextEditionDate: _d(2026, 11, 21), terrainDifficulty: .easy, raceType: .road),
        // Americas (non-US)
        KnownRace(name: "Toronto Waterfront Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 20,
                  elevationLossM: 20, country: "Canada", nextEditionDate: _d(2026, 10, 18), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Buenos Aires Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 20, elevationLossM: 20,
                  country: "Argentina", nextEditionDate: _d(2026, 10, 11), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Santiago Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 50, elevationLossM: 50,
                  country: "Chile", nextEditionDate: _d(2026, 4, 5), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "São Paulo Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 60, elevationLossM: 60,
                  country: "Brazil", nextEditionDate: _d(2026, 4, 5), terrainDifficulty: .easy, raceType: .road),
        // Africa
        KnownRace(name: "Cape Town Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 30, elevationLossM: 30,
                  country: "South Africa", nextEditionDate: _d(2026, 10, 18), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Marrakech Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 20, elevationLossM: 20,
                  country: "Morocco", nextEditionDate: _d(2026, 1, 25), terrainDifficulty: .easy, raceType: .road),
    ]

    // MARK: International Half Marathons

    private static let internationalHalfs: [KnownRace] = [
        KnownRace(name: "London Big Half", shortName: nil, distanceKm: 21.1, elevationGainM: 10, elevationLossM: 10,
                  country: "UK", nextEditionDate: _d(2026, 9, 6), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Berlin Half Marathon", shortName: nil, distanceKm: 21.1, elevationGainM: 20, elevationLossM: 20,
                  country: "Germany", nextEditionDate: _d(2026, 4, 5), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Great North Run", shortName: nil, distanceKm: 21.1, elevationGainM: 70, elevationLossM: 70,
                  country: "UK", nextEditionDate: _d(2026, 9, 13), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Lisbon Half Marathon", shortName: nil, distanceKm: 21.1, elevationGainM: 30, elevationLossM: 30,
                  country: "Portugal", nextEditionDate: _d(2026, 3, 22), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Copenhagen Half Marathon", shortName: nil, distanceKm: 21.1, elevationGainM: 10, elevationLossM: 10,
                  country: "Denmark", nextEditionDate: _d(2026, 9, 20), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Valencia Half Marathon", shortName: nil, distanceKm: 21.1, elevationGainM: 10, elevationLossM: 10,
                  country: "Spain", nextEditionDate: _d(2026, 10, 25), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Gothenburg Half Marathon", shortName: nil, distanceKm: 21.1, elevationGainM: 30, elevationLossM: 30,
                  country: "Sweden", nextEditionDate: _d(2026, 5, 23), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Prague Half Marathon", shortName: nil, distanceKm: 21.1, elevationGainM: 30, elevationLossM: 30,
                  country: "Czech Republic", nextEditionDate: _d(2026, 4, 4), terrainDifficulty: .easy, raceType: .road),
    ]

    // MARK: International 10K Races

    private static let internationalTenK: [KnownRace] = [
        KnownRace(name: "London 10K", shortName: nil, distanceKm: 10.0, elevationGainM: 10, elevationLossM: 10,
                  country: "UK", nextEditionDate: _d(2026, 7, 12), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Berlin 10K", shortName: nil, distanceKm: 10.0, elevationGainM: 10, elevationLossM: 10,
                  country: "Germany", terrainDifficulty: .easy, raceType: .road),
    ]
}
