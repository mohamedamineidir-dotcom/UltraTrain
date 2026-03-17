import Foundation

// swiftlint:disable:next identifier_name
private func _d(_ year: Int, _ month: Int, _ day: Int) -> Date {
    DateComponents(calendar: .current, year: year, month: month, day: day).date!
}

// MARK: - Africa & Middle East

extension RaceDatabase {

    static let africa: [KnownRace] = [

        // MARK: Morocco

        KnownRace(name: "Marathon des Sables", shortName: "MDS", distanceKm: 250, elevationGainM: 2500,
                  elevationLossM: 2500, country: "Morocco", nextEditionDate: _d(2026, 4, 3), terrainDifficulty: .easy),
        KnownRace(name: "Ultra Trail Atlas Toubkal", shortName: "UTAT", distanceKm: 105, elevationGainM: 5500,
                  elevationLossM: 5500, country: "Morocco", nextEditionDate: _d(2026, 10, 9), terrainDifficulty: .technical),
        KnownRace(name: "Zagora Sahara Trail", shortName: nil, distanceKm: 100, elevationGainM: 1200,
                  elevationLossM: 1200, country: "Morocco", nextEditionDate: _d(2026, 11, 7), terrainDifficulty: .easy),

        // MARK: South Africa

        KnownRace(name: "Comrades Marathon (Down Run)", shortName: "Comrades", distanceKm: 87, elevationGainM: 870,
                  elevationLossM: 1470, country: "South Africa", nextEditionDate: _d(2026, 6, 14), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "Two Oceans Ultra Marathon", shortName: "Two Oceans", distanceKm: 56, elevationGainM: 600,
                  elevationLossM: 600, country: "South Africa", nextEditionDate: _d(2026, 4, 4), terrainDifficulty: .easy, raceType: .road),
        KnownRace(name: "SkyRun 100K", shortName: nil, distanceKm: 100, elevationGainM: 4500,
                  elevationLossM: 4500, country: "South Africa", nextEditionDate: _d(2026, 11, 20), terrainDifficulty: .technical),
        KnownRace(name: "Hout Bay Trail Challenge 33K", shortName: nil, distanceKm: 33, elevationGainM: 1800,
                  elevationLossM: 1800, country: "South Africa", nextEditionDate: _d(2026, 8, 15), terrainDifficulty: .moderate),

        // MARK: East Africa

        KnownRace(name: "Kilimanjaro Stage Run", shortName: nil, distanceKm: 250, elevationGainM: 8000,
                  elevationLossM: 8000, country: "Tanzania", nextEditionDate: _d(2026, 2, 14), terrainDifficulty: .moderate),
        KnownRace(name: "Lewa Safari Marathon", shortName: nil, distanceKm: 42.195, elevationGainM: 400,
                  elevationLossM: 400, country: "Kenya", nextEditionDate: _d(2026, 6, 27), terrainDifficulty: .easy),

        // MARK: Islands

        KnownRace(name: "Trail de Rodrigues 60K", shortName: nil, distanceKm: 60, elevationGainM: 2800,
                  elevationLossM: 2800, country: "Mauritius", nextEditionDate: _d(2026, 5, 16), terrainDifficulty: .moderate),
        KnownRace(name: "Dodo Trail Mauritius 50K", shortName: nil, distanceKm: 50, elevationGainM: 2300,
                  elevationLossM: 2300, country: "Mauritius", nextEditionDate: _d(2026, 7, 18), terrainDifficulty: .moderate),

        // MARK: North Africa

        KnownRace(name: "Ultra Mirage El Djerid 100K", shortName: nil, distanceKm: 100, elevationGainM: 500,
                  elevationLossM: 500, country: "Tunisia", nextEditionDate: _d(2026, 10, 17), terrainDifficulty: .easy),
    ]
}
