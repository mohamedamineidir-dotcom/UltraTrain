import Foundation

// swiftlint:disable:next identifier_name
private func _d(_ year: Int, _ month: Int, _ day: Int) -> Date {
    DateComponents(calendar: .current, year: year, month: month, day: day).date!
}

// MARK: - UTMB World Series / By UTMB Circuit (2026 edition)
//
// Verified against the official UTMB World Series 2026 calendar and each
// event's own race page in May 2026. UTMB Mont-Blanc family (UTMB, CCC,
// TDS, OCC, MCC, PTL) lives in `RaceDatabase+WorldTrailMajors.swift`,
// not here.

extension RaceDatabase {

    static let utmbWorldSeries: [KnownRace] = [

        // MARK: TransLantau by UTMB (Hong Kong) — Nov 13-15, 2026

        KnownRace(name: "TransLantau by UTMB 140K", shortName: "TL140",
                  distanceKm: 140, elevationGainM: 6500, elevationLossM: 6500, country: "Hong Kong",
                  nextEditionDate: _d(2026, 11, 13), terrainDifficulty: .technical),
        KnownRace(name: "TransLantau by UTMB 100K", shortName: "TL100",
                  distanceKm: 104, elevationGainM: 4500, elevationLossM: 4500, country: "Hong Kong",
                  nextEditionDate: _d(2026, 11, 13), terrainDifficulty: .technical,
                  gpxAssetName: "translantau-tl100"),
        KnownRace(name: "TransLantau by UTMB 50K", shortName: "TL50",
                  distanceKm: 45, elevationGainM: 2500, elevationLossM: 2500, country: "Hong Kong",
                  nextEditionDate: _d(2026, 11, 14), terrainDifficulty: .moderate,
                  gpxAssetName: "translantau-tl50"),
        KnownRace(name: "TransLantau by UTMB 25K", shortName: "TL25",
                  distanceKm: 26, elevationGainM: 1400, elevationLossM: 1400, country: "Hong Kong",
                  nextEditionDate: _d(2026, 11, 15), terrainDifficulty: .moderate,
                  gpxAssetName: "translantau-tl25"),

        // MARK: Nice Côte d'Azur by UTMB (France) — Sep 25-27, 2026

        KnownRace(name: "Nice Côte d'Azur by UTMB 100M", shortName: "NCA 100M",
                  distanceKm: 165, elevationGainM: 8900, elevationLossM: 8900, country: "France",
                  nextEditionDate: _d(2026, 9, 25), terrainDifficulty: .technical,
                  gpxAssetName: "nice-100m"),
        KnownRace(name: "Nice Côte d'Azur by UTMB 100K", shortName: "NCA 100K",
                  distanceKm: 109, elevationGainM: 5400, elevationLossM: 5400, country: "France",
                  nextEditionDate: _d(2026, 9, 26), terrainDifficulty: .technical,
                  gpxAssetName: "nice-100k"),
        KnownRace(name: "Nice Côte d'Azur by UTMB 50K", shortName: "NCA 50K",
                  distanceKm: 50, elevationGainM: 2000, elevationLossM: 2000, country: "France",
                  nextEditionDate: _d(2026, 9, 26), terrainDifficulty: .moderate,
                  gpxAssetName: "nice-50k"),
        KnownRace(name: "Nice Côte d'Azur by UTMB 20K", shortName: "NCA 20K",
                  distanceKm: 23, elevationGainM: 680, elevationLossM: 680, country: "France",
                  nextEditionDate: _d(2026, 9, 27), terrainDifficulty: .moderate,
                  gpxAssetName: "nice-20k"),

        // MARK: HOKA Val d'Aran by UTMB (Spain) — Jul 1-5, 2026 (NEW 75K)

        KnownRace(name: "Val d'Aran by UTMB 165K", shortName: "VDA 165",
                  distanceKm: 163, elevationGainM: 10000, elevationLossM: 10000, country: "Spain",
                  nextEditionDate: _d(2026, 7, 1), terrainDifficulty: .technical,
                  gpxAssetName: "valdaran-165k"),
        KnownRace(name: "Val d'Aran by UTMB 110K", shortName: "CDH 110",
                  distanceKm: 110, elevationGainM: 6400, elevationLossM: 6400, country: "Spain",
                  nextEditionDate: _d(2026, 7, 2), terrainDifficulty: .technical,
                  gpxAssetName: "valdaran-110k"),
        KnownRace(name: "Val d'Aran by UTMB 75K", shortName: "TDL 75",
                  distanceKm: 75, elevationGainM: 5100, elevationLossM: 5100, country: "Spain",
                  nextEditionDate: _d(2026, 7, 3), terrainDifficulty: .technical,
                  gpxAssetName: "valdaran-75k"),
        KnownRace(name: "Val d'Aran by UTMB 55K", shortName: "PDA 55",
                  distanceKm: 55, elevationGainM: 3300, elevationLossM: 3300, country: "Spain",
                  nextEditionDate: _d(2026, 7, 3), terrainDifficulty: .technical,
                  gpxAssetName: "valdaran-55k"),

        // MARK: Chiangmai Thailand by UTMB — Nov 28 to Dec 6, 2026 (added 56K)

        KnownRace(name: "Chiangmai by UTMB 168K", shortName: "Chiang Dao 160",
                  distanceKm: 168, elevationGainM: 8100, elevationLossM: 8100, country: "Thailand",
                  nextEditionDate: _d(2026, 12, 3), terrainDifficulty: .technical,
                  gpxAssetName: "chiangmai-168k"),
        KnownRace(name: "Chiangmai by UTMB 96K", shortName: "Elephant 100",
                  distanceKm: 96, elevationGainM: 4600, elevationLossM: 4600, country: "Thailand",
                  nextEditionDate: _d(2026, 12, 4), terrainDifficulty: .technical,
                  gpxAssetName: "chiangmai-96k"),
        KnownRace(name: "Chiangmai by UTMB 56K", shortName: "Inthanon 60",
                  distanceKm: 56, elevationGainM: 2400, elevationLossM: 2400, country: "Thailand",
                  nextEditionDate: _d(2026, 12, 5), terrainDifficulty: .moderate),
        KnownRace(name: "Chiangmai by UTMB 39K", shortName: "Inthanon 40",
                  distanceKm: 39, elevationGainM: 2200, elevationLossM: 2200, country: "Thailand",
                  nextEditionDate: _d(2026, 12, 5), terrainDifficulty: .moderate),

        // MARK: Istria 100 by UTMB (Croatia) — Apr 10-12, 2026

        KnownRace(name: "Istria by UTMB 168K", shortName: nil,
                  distanceKm: 168, elevationGainM: 7140, elevationLossM: 7140, country: "Croatia",
                  nextEditionDate: _d(2026, 4, 10), terrainDifficulty: .technical,
                  gpxAssetName: "istria-168k"),
        KnownRace(name: "Istria by UTMB 110K", shortName: nil,
                  distanceKm: 111, elevationGainM: 4074, elevationLossM: 4074, country: "Croatia",
                  nextEditionDate: _d(2026, 4, 11), terrainDifficulty: .technical,
                  gpxAssetName: "istria-110k"),
        KnownRace(name: "Istria by UTMB 69K", shortName: nil,
                  distanceKm: 69, elevationGainM: 2331, elevationLossM: 2331, country: "Croatia",
                  nextEditionDate: _d(2026, 4, 11), terrainDifficulty: .moderate,
                  gpxAssetName: "istria-69k"),

        // MARK: Kullamannen by UTMB (Sweden) — Oct 30-31, 2026 (new 100M)

        KnownRace(name: "Kullamannen by UTMB 100M", shortName: "Kullamannen 100M",
                  distanceKm: 173, elevationGainM: 2300, elevationLossM: 2300, country: "Sweden",
                  nextEditionDate: _d(2026, 10, 30), terrainDifficulty: .moderate,
                  gpxAssetName: "kullamannen-100m"),
        KnownRace(name: "Kullamannen by UTMB 100K", shortName: "Sprint Ultra",
                  distanceKm: 108, elevationGainM: 749, elevationLossM: 749, country: "Sweden",
                  nextEditionDate: _d(2026, 10, 30), terrainDifficulty: .easy,
                  gpxAssetName: "kullamannen-100k"),
        KnownRace(name: "Kullamannen by UTMB 50K", shortName: "Seventh Seal",
                  distanceKm: 53, elevationGainM: 727, elevationLossM: 727, country: "Sweden",
                  nextEditionDate: _d(2026, 10, 31), terrainDifficulty: .easy,
                  gpxAssetName: "kullamannen-50k"),

        // MARK: Mt. Fuji 100 / Ultra-Trail Mt. Fuji (Japan) — Apr 24-25, 2026

        KnownRace(name: "Mt. Fuji 100", shortName: "UTMF",
                  distanceKm: 167, elevationGainM: 7038, elevationLossM: 7038, country: "Japan",
                  nextEditionDate: _d(2026, 4, 24), terrainDifficulty: .technical),
        KnownRace(name: "Mt. Fuji KAI 70K", shortName: "KAI 70K",
                  distanceKm: 70, elevationGainM: 3052, elevationLossM: 3052, country: "Japan",
                  nextEditionDate: _d(2026, 4, 25), terrainDifficulty: .technical),
        KnownRace(name: "Mt. Fuji ASUMI 40K", shortName: "ASUMI 40K",
                  distanceKm: 39, elevationGainM: 1481, elevationLossM: 1481, country: "Japan",
                  nextEditionDate: _d(2026, 4, 25), terrainDifficulty: .moderate),

        // MARK: Canyons Endurance Runs by UTMB (USA) — 2026 already ran, next Apr 2027

        KnownRace(name: "Canyons Endurance Runs 100mi", shortName: "Canyons 100M",
                  distanceKm: 161, elevationGainM: 5180, elevationLossM: 5180, country: "USA",
                  nextEditionDate: _d(2027, 4, 23), terrainDifficulty: .technical,
                  gpxAssetName: "canyons-100m"),
        KnownRace(name: "Canyons Endurance Runs 100K", shortName: "Canyons 100K",
                  distanceKm: 100, elevationGainM: 3350, elevationLossM: 3350, country: "USA",
                  nextEditionDate: _d(2027, 4, 24), terrainDifficulty: .moderate,
                  gpxAssetName: "canyons-100k"),
        KnownRace(name: "Canyons Endurance Runs 50K", shortName: "Canyons 50K",
                  distanceKm: 50, elevationGainM: 1700, elevationLossM: 1700, country: "USA",
                  nextEditionDate: _d(2027, 4, 25), terrainDifficulty: .moderate,
                  gpxAssetName: "canyons-50k"),
        KnownRace(name: "Canyons Endurance Runs 25K", shortName: "Canyons 25K",
                  distanceKm: 25, elevationGainM: 850, elevationLossM: 850, country: "USA",
                  nextEditionDate: _d(2027, 4, 25), terrainDifficulty: .moderate,
                  gpxAssetName: "canyons-25k"),

        // MARK: TransJeju by UTMB (South Korea) — Oct 2-3, 2026 (new 100M, 60K replaces 52K)

        KnownRace(name: "TransJeju by UTMB 100M", shortName: "Trans100M",
                  distanceKm: 148, elevationGainM: 5000, elevationLossM: 5000, country: "South Korea",
                  nextEditionDate: _d(2026, 10, 2), terrainDifficulty: .technical,
                  gpxAssetName: "transjeju-100m"),
        KnownRace(name: "TransJeju by UTMB 100K", shortName: "Trans100K",
                  distanceKm: 104, elevationGainM: 4000, elevationLossM: 4000, country: "South Korea",
                  nextEditionDate: _d(2026, 10, 2), terrainDifficulty: .technical,
                  gpxAssetName: "transjeju-100k"),
        KnownRace(name: "TransJeju by UTMB 60K", shortName: "Trans60K",
                  distanceKm: 60, elevationGainM: 1400, elevationLossM: 1400, country: "South Korea",
                  nextEditionDate: _d(2026, 10, 3), terrainDifficulty: .moderate,
                  gpxAssetName: "transjeju-60k"),

        // MARK: Patagonia Bariloche by UTMB (Argentina) — Nov 20-21, 2026

        KnownRace(name: "Patagonia Bariloche by UTMB 132K", shortName: "Tronador 130",
                  distanceKm: 132, elevationGainM: 6516, elevationLossM: 6516, country: "Argentina",
                  nextEditionDate: _d(2026, 11, 20), terrainDifficulty: .technical,
                  gpxAssetName: "bariloche-132k"),
        KnownRace(name: "Patagonia Bariloche by UTMB 86K", shortName: "Frey 80",
                  distanceKm: 86, elevationGainM: 4725, elevationLossM: 4725, country: "Argentina",
                  nextEditionDate: _d(2026, 11, 20), terrainDifficulty: .technical,
                  gpxAssetName: "bariloche-86k"),
        KnownRace(name: "Patagonia Bariloche by UTMB 58K", shortName: "Bella Vista 55",
                  distanceKm: 58, elevationGainM: 3000, elevationLossM: 3000, country: "Argentina",
                  nextEditionDate: _d(2026, 11, 21), terrainDifficulty: .technical,
                  gpxAssetName: "bariloche-58k"),

        // MARK: Malaysia Ultra-Trail by UTMB — Sep 12, 2026

        KnownRace(name: "Malaysia by UTMB 98K", shortName: "MY100",
                  distanceKm: 98, elevationGainM: 4802, elevationLossM: 4802, country: "Malaysia",
                  nextEditionDate: _d(2026, 9, 12), terrainDifficulty: .technical),
        KnownRace(name: "Malaysia by UTMB 55K", shortName: "MY50",
                  distanceKm: 55, elevationGainM: 1977, elevationLossM: 1977, country: "Malaysia",
                  nextEditionDate: _d(2026, 9, 12), terrainDifficulty: .moderate),

        // MARK: Gaoligong by UTMB (China) — Nov 28 to Dec 6, 2026 (new 2026 lineup)

        KnownRace(name: "Gaoligong by UTMB 165K", shortName: "Gaoligong 165",
                  distanceKm: 165, elevationGainM: 9000, elevationLossM: 9000, country: "China",
                  nextEditionDate: _d(2026, 11, 28), terrainDifficulty: .technical),
        KnownRace(name: "Gaoligong by UTMB 130K", shortName: "Gaoligong 130",
                  distanceKm: 130, elevationGainM: 7000, elevationLossM: 7000, country: "China",
                  nextEditionDate: _d(2026, 11, 28), terrainDifficulty: .technical),
        KnownRace(name: "Gaoligong by UTMB 55K", shortName: "Gaoligong 55",
                  distanceKm: 55, elevationGainM: 3200, elevationLossM: 3200, country: "China",
                  nextEditionDate: _d(2026, 11, 29), terrainDifficulty: .technical),

        // MARK: Grindstone by UTMB (USA) — Sep 18, 2026

        KnownRace(name: "Grindstone by UTMB 100mi", shortName: "Grindstone 100",
                  distanceKm: 167, elevationGainM: 6400, elevationLossM: 6400, country: "USA",
                  nextEditionDate: _d(2026, 9, 18), terrainDifficulty: .technical,
                  gpxAssetName: "grindstone-100m"),

        // MARK: EcoTrail Paris by UTMB — Mar 21-22, 2026

        KnownRace(name: "EcoTrail Paris by UTMB 80K", shortName: "EcoTrail 80K",
                  distanceKm: 80, elevationGainM: 1300, elevationLossM: 1300, country: "France",
                  nextEditionDate: _d(2026, 3, 21), terrainDifficulty: .easy),
        KnownRace(name: "EcoTrail Paris by UTMB 45K", shortName: "EcoTrail 45K",
                  distanceKm: 45, elevationGainM: 800, elevationLossM: 800, country: "France",
                  nextEditionDate: _d(2026, 3, 21), terrainDifficulty: .easy),
        KnownRace(name: "EcoTrail Paris by UTMB 30K", shortName: "EcoTrail 30K",
                  distanceKm: 30, elevationGainM: 409, elevationLossM: 409, country: "France",
                  nextEditionDate: _d(2026, 3, 22), terrainDifficulty: .easy),
        KnownRace(name: "EcoTrail Paris by UTMB 22K", shortName: "EcoTrail 22K",
                  distanceKm: 22, elevationGainM: 536, elevationLossM: 536, country: "France",
                  nextEditionDate: _d(2026, 3, 22), terrainDifficulty: .easy),

        // MARK: Mozart 100 by UTMB (Austria) — May 23, 2026

        KnownRace(name: "Mozart 100 by UTMB 119K", shortName: "Mozart 100K",
                  distanceKm: 119, elevationGainM: 5700, elevationLossM: 5700, country: "Austria",
                  nextEditionDate: _d(2026, 5, 23), terrainDifficulty: .technical,
                  gpxAssetName: "mozart100-119k"),
        KnownRace(name: "Mozart 100 by UTMB 72K", shortName: "Mozart Ultra",
                  distanceKm: 72, elevationGainM: 3300, elevationLossM: 3300, country: "Austria",
                  nextEditionDate: _d(2026, 5, 23), terrainDifficulty: .technical,
                  gpxAssetName: "mozart100-72k"),
        KnownRace(name: "Mozart 100 by UTMB 44K", shortName: "Mozart Marathon",
                  distanceKm: 44, elevationGainM: 1600, elevationLossM: 1600, country: "Austria",
                  nextEditionDate: _d(2026, 5, 23), terrainDifficulty: .moderate,
                  gpxAssetName: "mozart100-44k"),

        // MARK: Tarawera Ultra-Trail by UTMB (New Zealand) — 2026 already ran, next Feb 2027

        KnownRace(name: "Tarawera Ultramarathon 100M", shortName: "Tarawera 100M",
                  distanceKm: 163, elevationGainM: 3500, elevationLossM: 3500, country: "New Zealand",
                  nextEditionDate: _d(2027, 2, 13), terrainDifficulty: .moderate),
        KnownRace(name: "Tarawera Ultramarathon 102K", shortName: "Tarawera 102K",
                  distanceKm: 102, elevationGainM: 2300, elevationLossM: 2300, country: "New Zealand",
                  nextEditionDate: _d(2027, 2, 13), terrainDifficulty: .moderate),
        KnownRace(name: "Tarawera Ultramarathon 50K", shortName: "Tarawera 50K",
                  distanceKm: 50, elevationGainM: 1200, elevationLossM: 1200, country: "New Zealand",
                  nextEditionDate: _d(2027, 2, 13), terrainDifficulty: .moderate),
    ]
}
