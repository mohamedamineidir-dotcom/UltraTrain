import Foundation

// swiftlint:disable:next identifier_name
private func _d(_ year: Int, _ month: Int, _ day: Int) -> Date {
    DateComponents(calendar: .current, year: year, month: month, day: day).date!
}

// MARK: - Asia & Pacific

extension RaceDatabase {

    static let asiaPacific: [KnownRace] = [

        // MARK: Hong Kong

        KnownRace(name: "Hong Kong 100", shortName: "HK100", distanceKm: 103, elevationGainM: 4700,
                  elevationLossM: 4700, country: "Hong Kong", nextEditionDate: _d(2026, 1, 17), terrainDifficulty: .moderate),
        KnownRace(name: "Ultra-Trail Tai Mo Shan 162K", shortName: "UTTMS", distanceKm: 162, elevationGainM: 8200,
                  elevationLossM: 8200, country: "Hong Kong", nextEditionDate: _d(2026, 3, 7), terrainDifficulty: .moderate),
        KnownRace(name: "Oxfam Trailwalker Hong Kong", shortName: nil, distanceKm: 100, elevationGainM: 4700,
                  elevationLossM: 4700, country: "Hong Kong", nextEditionDate: _d(2026, 11, 14), terrainDifficulty: .moderate),
        KnownRace(name: "Vibram Hong Kong 100K", shortName: nil, distanceKm: 100, elevationGainM: 4800,
                  elevationLossM: 4800, country: "Hong Kong", nextEditionDate: _d(2026, 2, 14), terrainDifficulty: .moderate),

        // MARK: Japan

        KnownRace(name: "Shiga Kogen Skymarathon", shortName: nil, distanceKm: 42, elevationGainM: 2700,
                  elevationLossM: 2700, country: "Japan", nextEditionDate: _d(2026, 9, 26), terrainDifficulty: .moderate),
        KnownRace(name: "Aso Round Trail 100K", shortName: nil, distanceKm: 100, elevationGainM: 5000,
                  elevationLossM: 5000, country: "Japan", nextEditionDate: _d(2026, 5, 2), terrainDifficulty: .moderate),
        KnownRace(name: "Koumi 100", shortName: nil, distanceKm: 161, elevationGainM: 5500,
                  elevationLossM: 5500, country: "Japan", nextEditionDate: _d(2026, 5, 16), terrainDifficulty: .moderate),
        KnownRace(name: "Hasetsune Cup 71K", shortName: nil, distanceKm: 71, elevationGainM: 4582,
                  elevationLossM: 4582, country: "Japan", nextEditionDate: _d(2026, 10, 11), terrainDifficulty: .moderate),
        KnownRace(name: "Izu Trail Journey 72K", shortName: nil, distanceKm: 72, elevationGainM: 3800,
                  elevationLossM: 3800, country: "Japan", nextEditionDate: _d(2026, 12, 12), terrainDifficulty: .moderate),
        KnownRace(name: "Ontake 100K", shortName: nil, distanceKm: 100, elevationGainM: 5500,
                  elevationLossM: 5500, country: "Japan", nextEditionDate: _d(2026, 7, 18), terrainDifficulty: .moderate),

        // MARK: South Korea

        KnownRace(name: "Jeju Trail Running 100K", shortName: nil, distanceKm: 100, elevationGainM: 3500,
                  elevationLossM: 3500, country: "South Korea", nextEditionDate: _d(2026, 10, 17), terrainDifficulty: .moderate),

        // MARK: Taiwan

        KnownRace(name: "Formosa Trail 104K", shortName: nil, distanceKm: 104, elevationGainM: 6000,
                  elevationLossM: 6000, country: "Taiwan", nextEditionDate: _d(2026, 11, 21), terrainDifficulty: .technical),

        // MARK: Philippines

        KnownRace(name: "Ultra Trail Philippines 100K", shortName: nil, distanceKm: 100, elevationGainM: 4500,
                  elevationLossM: 4500, country: "Philippines", nextEditionDate: _d(2026, 2, 7), terrainDifficulty: .moderate),

        // MARK: India & Nepal

        KnownRace(name: "La Ultra - The High 111K", shortName: nil, distanceKm: 111, elevationGainM: 4000,
                  elevationLossM: 4000, country: "India", nextEditionDate: _d(2026, 8, 7), terrainDifficulty: .moderate),
        KnownRace(name: "Manaslu Trail Race 220K", shortName: nil, distanceKm: 220, elevationGainM: 12000,
                  elevationLossM: 12000, country: "Nepal", nextEditionDate: _d(2026, 11, 14), terrainDifficulty: .technical),

        // MARK: Australia

        KnownRace(name: "Ultra-Trail Kosciuszko 100K", shortName: nil, distanceKm: 100, elevationGainM: 4000,
                  elevationLossM: 4000, country: "Australia", nextEditionDate: _d(2026, 12, 4), terrainDifficulty: .moderate),
        KnownRace(name: "Heysen 105K", shortName: nil, distanceKm: 105, elevationGainM: 3900,
                  elevationLossM: 3900, country: "Australia", nextEditionDate: _d(2026, 6, 13), terrainDifficulty: .moderate),
        KnownRace(name: "Great Ocean Road 60K", shortName: nil, distanceKm: 60, elevationGainM: 2200,
                  elevationLossM: 2200, country: "Australia", nextEditionDate: _d(2026, 5, 16), terrainDifficulty: .easy),
        KnownRace(name: "Buffalo Stampede 75K", shortName: nil, distanceKm: 75, elevationGainM: 3800,
                  elevationLossM: 3800, country: "Australia", nextEditionDate: _d(2026, 4, 18), terrainDifficulty: .moderate),

        // MARK: New Zealand

        KnownRace(name: "Tarawera Ultramarathon 102K", shortName: nil, distanceKm: 102, elevationGainM: 2600,
                  elevationLossM: 2600, country: "New Zealand", nextEditionDate: _d(2026, 2, 7), terrainDifficulty: .moderate),
        KnownRace(name: "Tarawera Ultramarathon 50K", shortName: nil, distanceKm: 50, elevationGainM: 1300,
                  elevationLossM: 1300, country: "New Zealand", nextEditionDate: _d(2026, 2, 7), terrainDifficulty: .moderate),
        KnownRace(name: "Kepler Challenge 60K", shortName: nil, distanceKm: 60, elevationGainM: 2800,
                  elevationLossM: 2800, country: "New Zealand", nextEditionDate: _d(2026, 12, 5), terrainDifficulty: .moderate),
        KnownRace(name: "Old Ghost 85K", shortName: nil, distanceKm: 85, elevationGainM: 3300,
                  elevationLossM: 3300, country: "New Zealand", nextEditionDate: _d(2026, 3, 14), terrainDifficulty: .moderate),

        // MARK: Oman

        KnownRace(name: "Oman by UTMB Hajar Ultra 154K", shortName: "UTMB Oman", distanceKm: 154, elevationGainM: 8000,
                  elevationLossM: 8000, country: "Oman", nextEditionDate: _d(2026, 12, 10), terrainDifficulty: .technical),
        KnownRace(name: "Oman by UTMB Jabal Classic 103K", shortName: nil, distanceKm: 103, elevationGainM: 5000,
                  elevationLossM: 5000, country: "Oman", nextEditionDate: _d(2026, 12, 10), terrainDifficulty: .moderate),
        KnownRace(name: "Oman by UTMB 50K", shortName: nil, distanceKm: 50, elevationGainM: 2500,
                  elevationLossM: 2500, country: "Oman", nextEditionDate: _d(2026, 12, 11), terrainDifficulty: .moderate),
    ]
}
