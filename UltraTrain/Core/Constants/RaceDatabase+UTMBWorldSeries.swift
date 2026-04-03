import Foundation

// swiftlint:disable:next identifier_name
private func _d(_ year: Int, _ month: Int, _ day: Int) -> Date {
    DateComponents(calendar: .current, year: year, month: month, day: day).date!
}

// MARK: - UTMB World Series / By UTMB Circuit

extension RaceDatabase {

    static let utmbWorldSeries: [KnownRace] = [

        // MARK: Nice Côte d'Azur by UTMB (France)

        KnownRace(name: "Nice Côte d'Azur by UTMB 159K", shortName: "NCA 159K",
                  distanceKm: 159, elevationGainM: 8200, elevationLossM: 8200, country: "France",
                  nextEditionDate: _d(2026, 10, 3), terrainDifficulty: .moderate),
        KnownRace(name: "Nice Côte d'Azur by UTMB 107K", shortName: "NCA 107K",
                  distanceKm: 107, elevationGainM: 5152, elevationLossM: 5152, country: "France",
                  nextEditionDate: _d(2026, 10, 3), terrainDifficulty: .moderate),
        KnownRace(name: "Nice Côte d'Azur by UTMB 54K", shortName: "NCA 54K",
                  distanceKm: 54, elevationGainM: 2100, elevationLossM: 2100, country: "France",
                  nextEditionDate: _d(2026, 10, 3), terrainDifficulty: .moderate),
        KnownRace(name: "Nice Côte d'Azur by UTMB 22K", shortName: "NCA 22K",
                  distanceKm: 22, elevationGainM: 700, elevationLossM: 700, country: "France",
                  nextEditionDate: _d(2026, 10, 3), terrainDifficulty: .moderate),

        // MARK: TransLantau by UTMB (Hong Kong)

        KnownRace(name: "TransLantau by UTMB 116K", shortName: "TL120",
                  distanceKm: 116, elevationGainM: 5600, elevationLossM: 5600, country: "Hong Kong",
                  nextEditionDate: _d(2026, 11, 14), terrainDifficulty: .moderate),
        KnownRace(name: "TransLantau by UTMB 79K", shortName: "TL80",
                  distanceKm: 79, elevationGainM: 3900, elevationLossM: 3900, country: "Hong Kong",
                  nextEditionDate: _d(2026, 11, 14), terrainDifficulty: .moderate),
        KnownRace(name: "TransLantau by UTMB 52K", shortName: "TL50",
                  distanceKm: 52, elevationGainM: 2500, elevationLossM: 2500, country: "Hong Kong",
                  nextEditionDate: _d(2026, 11, 14), terrainDifficulty: .moderate),
        KnownRace(name: "TransLantau by UTMB 26K", shortName: "TL25",
                  distanceKm: 26, elevationGainM: 1400, elevationLossM: 1400, country: "Hong Kong",
                  nextEditionDate: _d(2026, 11, 14), terrainDifficulty: .moderate),

        // MARK: Chiangmai Thailand by UTMB

        KnownRace(name: "Chiangmai by UTMB 168K", shortName: "Chiang Dao 160",
                  distanceKm: 168, elevationGainM: 8100, elevationLossM: 8100, country: "Thailand",
                  nextEditionDate: _d(2026, 12, 5), terrainDifficulty: .moderate),
        KnownRace(name: "Chiangmai by UTMB 96K", shortName: "Elephant 100",
                  distanceKm: 96, elevationGainM: 4600, elevationLossM: 4600, country: "Thailand",
                  nextEditionDate: _d(2026, 12, 5), terrainDifficulty: .moderate),
        KnownRace(name: "Chiangmai by UTMB 39K", shortName: "Inthanon 50",
                  distanceKm: 39, elevationGainM: 2200, elevationLossM: 2200, country: "Thailand",
                  nextEditionDate: _d(2026, 12, 5), terrainDifficulty: .moderate),

        // MARK: Val d'Aran by UTMB (Spain)

        KnownRace(name: "Val d'Aran by UTMB 163K", shortName: "VDA 163",
                  distanceKm: 163, elevationGainM: 10000, elevationLossM: 10000, country: "Spain",
                  nextEditionDate: _d(2026, 7, 1), terrainDifficulty: .technical),
        KnownRace(name: "Val d'Aran by UTMB 110K", shortName: "CDH 110",
                  distanceKm: 110, elevationGainM: 6400, elevationLossM: 6400, country: "Spain",
                  nextEditionDate: _d(2026, 7, 1), terrainDifficulty: .technical),
        KnownRace(name: "Val d'Aran by UTMB 55K", shortName: "PDA 55",
                  distanceKm: 55, elevationGainM: 3300, elevationLossM: 3300, country: "Spain",
                  nextEditionDate: _d(2026, 7, 1), terrainDifficulty: .moderate),

        // MARK: Kullamannen by UTMB (Sweden)

        KnownRace(name: "Kullamannen by UTMB 103K", shortName: "Sprint Ultra",
                  distanceKm: 103, elevationGainM: 1045, elevationLossM: 1045, country: "Sweden",
                  nextEditionDate: _d(2026, 10, 17), terrainDifficulty: .easy),
        KnownRace(name: "Kullamannen by UTMB 50K", shortName: "Seventh Seal",
                  distanceKm: 50, elevationGainM: 834, elevationLossM: 834, country: "Sweden",
                  nextEditionDate: _d(2026, 10, 17), terrainDifficulty: .easy),

        // MARK: Ultra-Trail Mt. Fuji (Japan)

        KnownRace(name: "Ultra-Trail Mt. Fuji", shortName: "UTMF",
                  distanceKm: 167, elevationGainM: 6400, elevationLossM: 6400, country: "Japan",
                  nextEditionDate: _d(2026, 4, 24), terrainDifficulty: .moderate),
        KnownRace(name: "Ultra-Trail Mt. Fuji KAI 70K", shortName: "KAI 70K",
                  distanceKm: 70, elevationGainM: 3052, elevationLossM: 3052, country: "Japan",
                  nextEditionDate: _d(2026, 4, 24), terrainDifficulty: .moderate),
        KnownRace(name: "Ultra-Trail Mt. Fuji ASUMI 40K", shortName: "ASUMI 40K",
                  distanceKm: 40, elevationGainM: 1445, elevationLossM: 1445, country: "Japan",
                  nextEditionDate: _d(2026, 4, 24), terrainDifficulty: .moderate),

        // MARK: Canyons Endurance Runs by UTMB (USA)

        KnownRace(name: "Canyons Endurance Runs 100mi", shortName: "Canyons 100M",
                  distanceKm: 161, elevationGainM: 5550, elevationLossM: 5550, country: "USA",
                  nextEditionDate: _d(2026, 4, 25), terrainDifficulty: .moderate),
        KnownRace(name: "Canyons Endurance Runs 100K", shortName: "Canyons 100K",
                  distanceKm: 100, elevationGainM: 3750, elevationLossM: 3750, country: "USA",
                  nextEditionDate: _d(2026, 4, 25), terrainDifficulty: .moderate),
        KnownRace(name: "Canyons Endurance Runs 50K", shortName: "Canyons 50K",
                  distanceKm: 50, elevationGainM: 1700, elevationLossM: 1700, country: "USA",
                  nextEditionDate: _d(2026, 4, 25), terrainDifficulty: .moderate),
        KnownRace(name: "Canyons Endurance Runs 25K", shortName: "Canyons 25K",
                  distanceKm: 25, elevationGainM: 850, elevationLossM: 850, country: "USA",
                  nextEditionDate: _d(2026, 4, 25), terrainDifficulty: .moderate),

        // MARK: Istria by UTMB (Croatia)

        KnownRace(name: "Istria by UTMB 168K", shortName: nil,
                  distanceKm: 168, elevationGainM: 7140, elevationLossM: 7140, country: "Croatia",
                  nextEditionDate: _d(2026, 4, 11), terrainDifficulty: .moderate),
        KnownRace(name: "Istria by UTMB 110K", shortName: nil,
                  distanceKm: 110, elevationGainM: 4074, elevationLossM: 4074, country: "Croatia",
                  nextEditionDate: _d(2026, 4, 11), terrainDifficulty: .moderate),
        KnownRace(name: "Istria by UTMB 70K", shortName: nil,
                  distanceKm: 70, elevationGainM: 2331, elevationLossM: 2331, country: "Croatia",
                  nextEditionDate: _d(2026, 4, 11), terrainDifficulty: .moderate),

        // MARK: TransJeju by UTMB (South Korea, formerly Korea by UTMB)

        KnownRace(name: "TransJeju by UTMB 100K", shortName: "Trans100K",
                  distanceKm: 100, elevationGainM: 4200, elevationLossM: 4200, country: "South Korea",
                  nextEditionDate: _d(2026, 10, 30), terrainDifficulty: .moderate),
        KnownRace(name: "TransJeju by UTMB 52K", shortName: "Trans50K",
                  distanceKm: 52, elevationGainM: 2110, elevationLossM: 2110, country: "South Korea",
                  nextEditionDate: _d(2026, 10, 30), terrainDifficulty: .moderate),

        // MARK: Patagonia Bariloche by UTMB (Argentina)

        KnownRace(name: "Patagonia Bariloche by UTMB 132K", shortName: "Tronador 130",
                  distanceKm: 132, elevationGainM: 6516, elevationLossM: 6516, country: "Argentina",
                  nextEditionDate: _d(2026, 11, 7), terrainDifficulty: .moderate),
        KnownRace(name: "Patagonia Bariloche by UTMB 86K", shortName: "Frey 80",
                  distanceKm: 86, elevationGainM: 4725, elevationLossM: 4725, country: "Argentina",
                  nextEditionDate: _d(2026, 11, 7), terrainDifficulty: .moderate),
        KnownRace(name: "Patagonia Bariloche by UTMB 58K", shortName: nil,
                  distanceKm: 58, elevationGainM: 3000, elevationLossM: 3000, country: "Argentina",
                  nextEditionDate: _d(2026, 11, 7), terrainDifficulty: .moderate),

        // MARK: Malaysia Ultra-Trail by UTMB

        KnownRace(name: "Malaysia by UTMB 98K", shortName: "MY100",
                  distanceKm: 98, elevationGainM: 4802, elevationLossM: 4802, country: "Malaysia",
                  nextEditionDate: _d(2026, 9, 12), terrainDifficulty: .moderate),
        KnownRace(name: "Malaysia by UTMB 55K", shortName: "MY50",
                  distanceKm: 55, elevationGainM: 1977, elevationLossM: 1977, country: "Malaysia",
                  nextEditionDate: _d(2026, 9, 12), terrainDifficulty: .moderate),

        // MARK: Gaoligong by UTMB (China)

        KnownRace(name: "Gaoligong by UTMB 124K", shortName: nil,
                  distanceKm: 124, elevationGainM: 6690, elevationLossM: 6690, country: "China",
                  nextEditionDate: _d(2026, 12, 12), terrainDifficulty: .moderate),
        KnownRace(name: "Gaoligong by UTMB 55K", shortName: nil,
                  distanceKm: 55, elevationGainM: 3200, elevationLossM: 3200, country: "China",
                  nextEditionDate: _d(2026, 12, 12), terrainDifficulty: .moderate),

        // MARK: Grindstone by UTMB (USA)

        KnownRace(name: "Grindstone by UTMB 100mi", shortName: "Grindstone 100",
                  distanceKm: 173, elevationGainM: 6420, elevationLossM: 6420, country: "USA",
                  nextEditionDate: _d(2026, 9, 18), terrainDifficulty: .moderate),

        // MARK: EcoTrail Paris by UTMB (France)

        KnownRace(name: "EcoTrail Paris by UTMB 81K", shortName: "EcoTrail 80K",
                  distanceKm: 81, elevationGainM: 1200, elevationLossM: 1200, country: "France",
                  nextEditionDate: _d(2026, 3, 21), terrainDifficulty: .easy),
        KnownRace(name: "EcoTrail Paris by UTMB 46K", shortName: "EcoTrail 45K",
                  distanceKm: 46, elevationGainM: 800, elevationLossM: 800, country: "France",
                  nextEditionDate: _d(2026, 3, 21), terrainDifficulty: .easy),
        KnownRace(name: "EcoTrail Paris by UTMB 32K", shortName: "EcoTrail 30K",
                  distanceKm: 32, elevationGainM: 420, elevationLossM: 420, country: "France",
                  nextEditionDate: _d(2026, 3, 21), terrainDifficulty: .easy),
        KnownRace(name: "EcoTrail Paris by UTMB 19K", shortName: "EcoTrail 18K",
                  distanceKm: 19, elevationGainM: 460, elevationLossM: 460, country: "France",
                  nextEditionDate: _d(2026, 3, 21), terrainDifficulty: .easy),

        // MARK: Mozart 100 by UTMB (Austria)

        KnownRace(name: "Mozart 100 by UTMB 119K", shortName: "Mozart 100K",
                  distanceKm: 119, elevationGainM: 5700, elevationLossM: 5700, country: "Austria",
                  nextEditionDate: _d(2026, 5, 23), terrainDifficulty: .moderate),
        KnownRace(name: "Mozart 100 by UTMB 72K", shortName: "Mozart Ultra",
                  distanceKm: 72, elevationGainM: 3300, elevationLossM: 3300, country: "Austria",
                  nextEditionDate: _d(2026, 5, 23), terrainDifficulty: .moderate),
        KnownRace(name: "Mozart 100 by UTMB 44K", shortName: "Mozart Marathon",
                  distanceKm: 44, elevationGainM: 1600, elevationLossM: 1600, country: "Austria",
                  nextEditionDate: _d(2026, 5, 23), terrainDifficulty: .moderate),
    ]
}
