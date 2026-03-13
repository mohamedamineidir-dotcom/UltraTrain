import Foundation

// swiftlint:disable:next identifier_name
private func _d(_ year: Int, _ month: Int, _ day: Int) -> Date {
    DateComponents(calendar: .current, year: year, month: month, day: day).date!
}

// MARK: - Asia & Pacific

extension RaceDatabase {

    static let asiaPacific: [KnownRace] = [

        // MARK: Hong Kong

        KnownRace(name: "Hong Kong 100", shortName: "HK100",
                  distanceKm: 100, elevationGainM: 4700, elevationLossM: 4700, country: "Hong Kong",
                  nextEditionDate: _d(2026, 1, 17), terrainDifficulty: .moderate),
        KnownRace(name: "Ultra-Trail Tai Mo Shan", shortName: "UTTMS",
                  distanceKm: 162, elevationGainM: 8200, elevationLossM: 8200, country: "Hong Kong",
                  nextEditionDate: _d(2026, 3, 7), terrainDifficulty: .moderate),
        KnownRace(name: "Oxfam Trailwalker Hong Kong", shortName: nil,
                  distanceKm: 100, elevationGainM: 4700, elevationLossM: 4700, country: "Hong Kong",
                  nextEditionDate: _d(2026, 11, 14), terrainDifficulty: .moderate),

        // MARK: New Zealand

        KnownRace(name: "Tarawera Ultramarathon", shortName: nil,
                  distanceKm: 102, elevationGainM: 2600, elevationLossM: 2600, country: "New Zealand",
                  nextEditionDate: _d(2026, 2, 7), terrainDifficulty: .moderate),

        // MARK: Australia

        KnownRace(name: "Ultra-Trail Kosciuszko", shortName: nil,
                  distanceKm: 100, elevationGainM: 4000, elevationLossM: 4000, country: "Australia",
                  nextEditionDate: _d(2026, 12, 4), terrainDifficulty: .moderate),

        // MARK: Oman

        KnownRace(name: "UTMB Oman 170K", shortName: "UTMB Oman",
                  distanceKm: 170, elevationGainM: 8000, elevationLossM: 8000, country: "Oman",
                  nextEditionDate: _d(2026, 12, 3), terrainDifficulty: .technical),
        KnownRace(name: "UTMB Oman 100K", shortName: nil,
                  distanceKm: 100, elevationGainM: 5000, elevationLossM: 5000, country: "Oman",
                  nextEditionDate: _d(2026, 12, 3), terrainDifficulty: .moderate),
        KnownRace(name: "UTMB Oman 50K", shortName: nil,
                  distanceKm: 50, elevationGainM: 2500, elevationLossM: 2500, country: "Oman",
                  nextEditionDate: _d(2026, 12, 4), terrainDifficulty: .moderate),
    ]
}
