import Foundation

// swiftlint:disable:next identifier_name
private func _d(_ year: Int, _ month: Int, _ day: Int) -> Date {
    DateComponents(calendar: .current, year: year, month: month, day: day).date!
}

// MARK: - World Trail Majors

extension RaceDatabase {

    static let worldTrailMajors: [KnownRace] = [

        // MARK: UTMB Mont-Blanc (France)

        KnownRace(name: "Ultra-Trail du Mont-Blanc", shortName: "UTMB",
                  distanceKm: 176, elevationGainM: 10000, elevationLossM: 10000, country: "France",
                  nextEditionDate: _d(2026, 8, 28), terrainDifficulty: .technical),
        KnownRace(name: "Courmayeur-Champex-Chamonix", shortName: "CCC",
                  distanceKm: 101, elevationGainM: 6050, elevationLossM: 6050, country: "France",
                  nextEditionDate: _d(2026, 8, 29), terrainDifficulty: .technical),
        KnownRace(name: "Sur les Traces des Ducs de Savoie", shortName: "TDS",
                  distanceKm: 148, elevationGainM: 9300, elevationLossM: 9300, country: "France",
                  nextEditionDate: _d(2026, 8, 26), terrainDifficulty: .technical),
        KnownRace(name: "Orsières-Champex-Chamonix", shortName: "OCC",
                  distanceKm: 57, elevationGainM: 3500, elevationLossM: 3500, country: "France",
                  nextEditionDate: _d(2026, 8, 27), terrainDifficulty: .moderate),
        KnownRace(name: "Martigny-Combe-Champex", shortName: "MCC",
                  distanceKm: 40, elevationGainM: 2350, elevationLossM: 2350, country: "Switzerland",
                  nextEditionDate: _d(2026, 8, 25), terrainDifficulty: .moderate),
        KnownRace(name: "ETC - Évasion Trail du Courmayeur", shortName: "ETC",
                  distanceKm: 15, elevationGainM: 1000, elevationLossM: 1000, country: "Italy",
                  nextEditionDate: _d(2026, 8, 25), terrainDifficulty: .technical),
        KnownRace(name: "La Petite Trotte à Léon", shortName: "PTL",
                  distanceKm: 300, elevationGainM: 25000, elevationLossM: 25000, country: "France",
                  nextEditionDate: _d(2026, 8, 25), terrainDifficulty: .extreme),

        // MARK: Western States 100 (USA)

        KnownRace(name: "Western States 100", shortName: "WSER",
                  distanceKm: 161, elevationGainM: 5500, elevationLossM: 7000, country: "USA",
                  nextEditionDate: _d(2026, 6, 27), terrainDifficulty: .moderate),

        // MARK: Ultra-Trail Cape Town (South Africa)

        KnownRace(name: "Ultra-Trail Cape Town 100 Mile", shortName: "UTCT 100M",
                  distanceKm: 170, elevationGainM: 7516, elevationLossM: 7516, country: "South Africa",
                  nextEditionDate: _d(2026, 11, 28), terrainDifficulty: .technical),
        KnownRace(name: "Ultra-Trail Cape Town 100K", shortName: "UTCT 100K",
                  distanceKm: 98, elevationGainM: 4972, elevationLossM: 4972, country: "South Africa",
                  nextEditionDate: _d(2026, 11, 28), terrainDifficulty: .technical),
        KnownRace(name: "Ultra-Trail Cape Town 55K", shortName: "UTCT PT55",
                  distanceKm: 55, elevationGainM: 2706, elevationLossM: 2706, country: "South Africa",
                  nextEditionDate: _d(2026, 11, 28), terrainDifficulty: .technical),
        KnownRace(name: "Ultra-Trail Cape Town 36K", shortName: "UTCT 36K",
                  distanceKm: 36, elevationGainM: 1954, elevationLossM: 1954, country: "South Africa",
                  nextEditionDate: _d(2026, 11, 28), terrainDifficulty: .technical),
        KnownRace(name: "Ultra-Trail Cape Town 23K", shortName: "UTCT EX23",
                  distanceKm: 23, elevationGainM: 1144, elevationLossM: 1144, country: "South Africa",
                  nextEditionDate: _d(2026, 11, 28), terrainDifficulty: .moderate),
        KnownRace(name: "Ultra-Trail Cape Town 16K", shortName: "UTCT KS16",
                  distanceKm: 16, elevationGainM: 665, elevationLossM: 665, country: "South Africa",
                  nextEditionDate: _d(2026, 11, 28), terrainDifficulty: .moderate),

        // MARK: Penyagolosa Trails (Spain)

        KnownRace(name: "Penyagolosa Trails CSP", shortName: "CSP",
                  distanceKm: 106, elevationGainM: 5600, elevationLossM: 4400, country: "Spain",
                  nextEditionDate: _d(2026, 4, 18), terrainDifficulty: .moderate),
        KnownRace(name: "Penyagolosa Trails MiM", shortName: "MiM",
                  distanceKm: 60, elevationGainM: 3300, elevationLossM: 3300, country: "Spain",
                  nextEditionDate: _d(2026, 4, 18), terrainDifficulty: .moderate),

        // MARK: Ultra Pirineu (Spain)

        KnownRace(name: "Ultra Pirineu 100K", shortName: nil,
                  distanceKm: 101, elevationGainM: 6600, elevationLossM: 6600, country: "Spain",
                  nextEditionDate: _d(2026, 9, 26), terrainDifficulty: .technical),
        KnownRace(name: "Ultra Pirineu 42K", shortName: nil,
                  distanceKm: 42, elevationGainM: 2700, elevationLossM: 2700, country: "Spain",
                  nextEditionDate: _d(2026, 9, 26), terrainDifficulty: .moderate),

        // MARK: TransGranCanaria (Spain)

        KnownRace(name: "TransGranCanaria Classic", shortName: "TGC Classic",
                  distanceKm: 126, elevationGainM: 6764, elevationLossM: 6764, country: "Spain",
                  nextEditionDate: _d(2026, 3, 6), terrainDifficulty: .technical),
        KnownRace(name: "TransGranCanaria Advanced", shortName: "TGC Advanced",
                  distanceKm: 82, elevationGainM: 4314, elevationLossM: 4314, country: "Spain",
                  nextEditionDate: _d(2026, 3, 6), terrainDifficulty: .technical),
        KnownRace(name: "TransGranCanaria Marathon", shortName: "TGC Marathon",
                  distanceKm: 47, elevationGainM: 1784, elevationLossM: 1784, country: "Spain",
                  nextEditionDate: _d(2026, 3, 7), terrainDifficulty: .moderate),
        KnownRace(name: "TransGranCanaria Half", shortName: "TGC Half",
                  distanceKm: 23, elevationGainM: 1817, elevationLossM: 1817, country: "Spain",
                  nextEditionDate: _d(2026, 3, 7), terrainDifficulty: .moderate),

        // MARK: Lavaredo Ultra Trail (Italy)

        KnownRace(name: "Lavaredo Ultra Trail 120K", shortName: "LUT",
                  distanceKm: 120, elevationGainM: 5800, elevationLossM: 5800, country: "Italy",
                  nextEditionDate: _d(2026, 6, 26), terrainDifficulty: .technical),
        KnownRace(name: "Lavaredo 80K", shortName: nil,
                  distanceKm: 80, elevationGainM: 4600, elevationLossM: 4600, country: "Italy",
                  nextEditionDate: _d(2026, 6, 26), terrainDifficulty: .technical),
        KnownRace(name: "Lavaredo 50K", shortName: nil,
                  distanceKm: 50, elevationGainM: 2600, elevationLossM: 2600, country: "Italy",
                  nextEditionDate: _d(2026, 6, 26), terrainDifficulty: .technical),
        KnownRace(name: "Lavaredo 20K", shortName: nil,
                  distanceKm: 20, elevationGainM: 1000, elevationLossM: 1000, country: "Italy",
                  nextEditionDate: _d(2026, 6, 26), terrainDifficulty: .technical),

        // MARK: Ultra-Trail Australia

        KnownRace(name: "Ultra-Trail Australia 100K", shortName: "UTA 100",
                  distanceKm: 100, elevationGainM: 4400, elevationLossM: 4400, country: "Australia",
                  nextEditionDate: _d(2026, 5, 16), terrainDifficulty: .moderate),
        KnownRace(name: "Ultra-Trail Australia 50K", shortName: "UTA 50",
                  distanceKm: 50, elevationGainM: 2400, elevationLossM: 2400, country: "Australia",
                  nextEditionDate: _d(2026, 5, 16), terrainDifficulty: .moderate),
        KnownRace(name: "Ultra-Trail Australia 22K", shortName: "UTA 22",
                  distanceKm: 22, elevationGainM: 1200, elevationLossM: 1090, country: "Australia",
                  nextEditionDate: _d(2026, 5, 16), terrainDifficulty: .moderate),

        // MARK: MIUT Madeira (Portugal)

        KnownRace(name: "Madeira Island Ultra Trail", shortName: "MIUT Ultra",
                  distanceKm: 118, elevationGainM: 6640, elevationLossM: 6640, country: "Portugal",
                  nextEditionDate: _d(2026, 4, 25), terrainDifficulty: .technical),
        KnownRace(name: "MIUT 86K", shortName: nil,
                  distanceKm: 86, elevationGainM: 4873, elevationLossM: 4873, country: "Portugal",
                  nextEditionDate: _d(2026, 4, 25), terrainDifficulty: .moderate),
        KnownRace(name: "MIUT 56K", shortName: nil,
                  distanceKm: 56, elevationGainM: 3315, elevationLossM: 3315, country: "Portugal",
                  nextEditionDate: _d(2026, 4, 25), terrainDifficulty: .moderate),
        KnownRace(name: "MIUT 16K", shortName: nil,
                  distanceKm: 16, elevationGainM: 400, elevationLossM: 400, country: "Portugal",
                  nextEditionDate: _d(2026, 4, 25), terrainDifficulty: .moderate),

        // MARK: Trail 100 Andorra

        KnownRace(name: "Trail 100 Andorra Ultra 105K", shortName: nil,
                  distanceKm: 105, elevationGainM: 6900, elevationLossM: 6900, country: "Andorra",
                  nextEditionDate: _d(2026, 6, 13), terrainDifficulty: .technical),
        KnownRace(name: "Trail 100 Andorra 80K", shortName: nil,
                  distanceKm: 79, elevationGainM: 3900, elevationLossM: 3900, country: "Andorra",
                  nextEditionDate: _d(2026, 6, 13), terrainDifficulty: .moderate),
        KnownRace(name: "Trail 100 Andorra 50K", shortName: nil,
                  distanceKm: 50, elevationGainM: 3400, elevationLossM: 3400, country: "Andorra",
                  nextEditionDate: _d(2026, 6, 13), terrainDifficulty: .moderate),
    ]
}
