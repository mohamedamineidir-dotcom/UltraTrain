import Foundation

// swiftlint:disable:next identifier_name
private func _d(_ year: Int, _ month: Int, _ day: Int) -> Date {
    DateComponents(calendar: .current, year: year, month: month, day: day).date!
}

// MARK: - USA Road Races

extension RaceDatabase {

    static let usaRoadRaces: [KnownRace] = usaMarathons + usaHalfMarathons + usaTenK

    // MARK: US Marathons (excluding World Majors: Boston, NYC, Chicago)

    private static let usaMarathons: [KnownRace] = [
        KnownRace(name: "Los Angeles Marathon", shortName: "LA Marathon", distanceKm: 42.195, elevationGainM: 100,
                  elevationLossM: 100, country: "USA", nextEditionDate: _d(2026, 3, 8), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Marine Corps Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 100, elevationLossM: 100,
                  country: "USA", nextEditionDate: _d(2026, 10, 25), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Honolulu Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 70, elevationLossM: 70,
                  country: "USA", nextEditionDate: _d(2026, 12, 13), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "San Francisco Marathon", shortName: "SF Marathon", distanceKm: 42.195, elevationGainM: 250,
                  elevationLossM: 250, country: "USA", nextEditionDate: _d(2026, 7, 26), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Twin Cities Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 100, elevationLossM: 100,
                  country: "USA", nextEditionDate: _d(2026, 10, 4), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Philadelphia Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 60, elevationLossM: 60,
                  country: "USA", nextEditionDate: _d(2026, 11, 22), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Houston Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 10, elevationLossM: 10,
                  country: "USA", nextEditionDate: _d(2026, 1, 18), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "St. George Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 30, elevationLossM: 790,
                  country: "USA", nextEditionDate: _d(2026, 10, 3), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "California International Marathon", shortName: "CIM", distanceKm: 42.195, elevationGainM: 20,
                  elevationLossM: 110, country: "USA", nextEditionDate: _d(2026, 12, 6), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Grandma's Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 70, elevationLossM: 170,
                  country: "USA", nextEditionDate: _d(2026, 6, 20), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Big Sur Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 500, elevationLossM: 500,
                  country: "USA", nextEditionDate: _d(2026, 4, 26), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Austin Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 120, elevationLossM: 120,
                  country: "USA", nextEditionDate: _d(2026, 2, 15), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Detroit Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 30, elevationLossM: 30,
                  country: "USA", nextEditionDate: _d(2026, 10, 18), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Portland Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 80, elevationLossM: 80,
                  country: "USA", nextEditionDate: _d(2026, 10, 4), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Revel Big Cottonwood", shortName: nil, distanceKm: 42.195, elevationGainM: 20, elevationLossM: 820,
                  country: "USA", nextEditionDate: _d(2026, 9, 12), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Nashville Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 120, elevationLossM: 120,
                  country: "USA", nextEditionDate: _d(2026, 4, 25), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "San Diego Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 60, elevationLossM: 60,
                  country: "USA", nextEditionDate: _d(2026, 6, 7), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Bayshore Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 30, elevationLossM: 30,
                  country: "USA", nextEditionDate: _d(2026, 5, 23), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Eugene Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 40, elevationLossM: 40,
                  country: "USA", nextEditionDate: _d(2026, 4, 26), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Milwaukee Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 50, elevationLossM: 50,
                  country: "USA", nextEditionDate: _d(2026, 4, 12), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Hartford Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 80, elevationLossM: 80,
                  country: "USA", nextEditionDate: _d(2026, 10, 10), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Tucson Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 30, elevationLossM: 300,
                  country: "USA", nextEditionDate: _d(2026, 12, 6), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Jacksonville Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 10, elevationLossM: 10,
                  country: "USA", nextEditionDate: _d(2026, 2, 8), terrainDifficulty: .easy, raceType: .road),
    ]

    // MARK: US Half Marathons

    private static let usaHalfMarathons: [KnownRace] = [
        KnownRace(name: "NYC Half Marathon", shortName: "NYC Half", distanceKm: 21.1, elevationGainM: 80, elevationLossM: 80,
                  country: "USA", nextEditionDate: _d(2026, 3, 15), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Rock'n'Roll Las Vegas", shortName: nil, distanceKm: 21.1, elevationGainM: 30, elevationLossM: 30,
                  country: "USA", nextEditionDate: _d(2026, 2, 22), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Brooklyn Half Marathon", shortName: nil, distanceKm: 21.1, elevationGainM: 40, elevationLossM: 40,
                  country: "USA", nextEditionDate: _d(2026, 5, 16), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Disney Princess Half Marathon", shortName: nil, distanceKm: 21.1, elevationGainM: 10,
                  elevationLossM: 10, country: "USA", nextEditionDate: _d(2026, 2, 22), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Disney Wine & Dine Half Marathon", shortName: nil, distanceKm: 21.1, elevationGainM: 10,
                  elevationLossM: 10, country: "USA", nextEditionDate: _d(2026, 11, 7), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Rock'n'Roll San Diego", shortName: nil, distanceKm: 21.1, elevationGainM: 40, elevationLossM: 40,
                  country: "USA", nextEditionDate: _d(2026, 6, 7), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Rock'n'Roll Nashville", shortName: nil, distanceKm: 21.1, elevationGainM: 60, elevationLossM: 60,
                  country: "USA", nextEditionDate: _d(2026, 4, 25), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "DC Half Marathon", shortName: nil, distanceKm: 21.1, elevationGainM: 40, elevationLossM: 40,
                  country: "USA", nextEditionDate: _d(2026, 3, 14), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Indianapolis Mini Marathon", shortName: "Indy Mini", distanceKm: 21.1, elevationGainM: 30,
                  elevationLossM: 30, country: "USA", nextEditionDate: _d(2026, 5, 2), terrainDifficulty: .easy, raceType: .road),
    ]

    // MARK: US 10K Races

    private static let usaTenK: [KnownRace] = [
        KnownRace(name: "NYC 10K", shortName: nil, distanceKm: 10.0, elevationGainM: 30, elevationLossM: 30,
                  country: "USA", terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "AJC Peachtree Road Race", shortName: "Peachtree 10K", distanceKm: 10.0, elevationGainM: 50,
                  elevationLossM: 50, country: "USA", nextEditionDate: _d(2026, 7, 4), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Cooper River Bridge Run", shortName: "Bridge Run 10K", distanceKm: 10.0, elevationGainM: 30,
                  elevationLossM: 30, country: "USA", nextEditionDate: _d(2026, 4, 4), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Bolder Boulder", shortName: nil, distanceKm: 10.0, elevationGainM: 60, elevationLossM: 60,
                  country: "USA", nextEditionDate: _d(2026, 5, 25), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Bay to Breakers", shortName: nil, distanceKm: 12.0, elevationGainM: 100, elevationLossM: 100,
                  country: "USA", nextEditionDate: _d(2026, 5, 17), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Bloomsday Run", shortName: nil, distanceKm: 12.0, elevationGainM: 70, elevationLossM: 70,
                  country: "USA", nextEditionDate: _d(2026, 5, 3), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Crescent City Classic", shortName: nil, distanceKm: 10.0, elevationGainM: 5, elevationLossM: 5,
                  country: "USA", nextEditionDate: _d(2026, 3, 28), terrainDifficulty: .easy, raceType: .road),
    ]
}
