import Foundation

// swiftlint:disable:next identifier_name
private func _d(_ year: Int, _ month: Int, _ day: Int) -> Date {
    DateComponents(calendar: .current, year: year, month: month, day: day).date!
}

// MARK: - Europe

extension RaceDatabase {

    static let europe: [KnownRace] = [

        // MARK: France (Réunion)

        KnownRace(name: "Diagonale des Fous", shortName: "Grand Raid",
                  distanceKm: 165, elevationGainM: 9576, elevationLossM: 9576, country: "France (Réunion)",
                  nextEditionDate: _d(2026, 10, 22), terrainDifficulty: .extreme),
        KnownRace(name: "Trail de Bourbon", shortName: nil,
                  distanceKm: 111, elevationGainM: 6433, elevationLossM: 6433, country: "France (Réunion)",
                  nextEditionDate: _d(2026, 10, 23), terrainDifficulty: .technical),
        KnownRace(name: "Mascareignes", shortName: nil,
                  distanceKm: 65, elevationGainM: 3505, elevationLossM: 3505, country: "France (Réunion)",
                  nextEditionDate: _d(2026, 10, 23), terrainDifficulty: .moderate),
        KnownRace(name: "Grand Trail de la Réunion", shortName: nil,
                  distanceKm: 165, elevationGainM: 9576, elevationLossM: 9576, country: "France (Réunion)",
                  nextEditionDate: _d(2026, 10, 22), terrainDifficulty: .moderate),

        // MARK: Italy

        KnownRace(name: "Tor des Géants", shortName: "TDG",
                  distanceKm: 330, elevationGainM: 24000, elevationLossM: 24000, country: "Italy",
                  nextEditionDate: _d(2026, 9, 6), terrainDifficulty: .technical),
        KnownRace(name: "Tor des Glaciers", shortName: nil,
                  distanceKm: 450, elevationGainM: 32000, elevationLossM: 32000, country: "Italy",
                  nextEditionDate: _d(2026, 9, 1), terrainDifficulty: .technical),

        // MARK: Spain

        KnownRace(name: "Transvulcania", shortName: nil,
                  distanceKm: 74, elevationGainM: 4350, elevationLossM: 4350, country: "Spain",
                  nextEditionDate: _d(2026, 5, 9), terrainDifficulty: .moderate),
        KnownRace(name: "Zegama-Aizkorri Marathon", shortName: "Zegama",
                  distanceKm: 42, elevationGainM: 2736, elevationLossM: 2736, country: "Spain",
                  nextEditionDate: _d(2026, 5, 24), terrainDifficulty: .technical),
        KnownRace(name: "Gran Trail Peñalara 110K", shortName: nil,
                  distanceKm: 110, elevationGainM: 5500, elevationLossM: 5500, country: "Spain",
                  nextEditionDate: _d(2026, 6, 27), terrainDifficulty: .moderate),
        KnownRace(name: "Gran Trail Peñalara 60K", shortName: nil,
                  distanceKm: 60, elevationGainM: 3000, elevationLossM: 3000, country: "Spain",
                  nextEditionDate: _d(2026, 6, 27), terrainDifficulty: .moderate),
        KnownRace(name: "Ultra Sierra Nevada", shortName: nil,
                  distanceKm: 102, elevationGainM: 5500, elevationLossM: 5500, country: "Spain",
                  nextEditionDate: _d(2026, 7, 4), terrainDifficulty: .moderate),
        KnownRace(name: "Penyagolosa Trails MiM 107K", shortName: "MiM",
                  distanceKm: 107, elevationGainM: 5600, elevationLossM: 5600, country: "Spain",
                  nextEditionDate: _d(2026, 5, 2), terrainDifficulty: .technical),

        // MARK: Switzerland

        KnownRace(name: "Eiger Ultra Trail E101", shortName: "E101",
                  distanceKm: 101, elevationGainM: 6700, elevationLossM: 6700, country: "Switzerland",
                  nextEditionDate: _d(2026, 7, 18), terrainDifficulty: .technical),
        KnownRace(name: "Eiger Ultra Trail E51", shortName: "E51",
                  distanceKm: 51, elevationGainM: 3400, elevationLossM: 3400, country: "Switzerland",
                  nextEditionDate: _d(2026, 7, 18), terrainDifficulty: .technical),
        KnownRace(name: "Eiger Ultra Trail E35", shortName: "E35",
                  distanceKm: 35, elevationGainM: 2300, elevationLossM: 2300, country: "Switzerland",
                  nextEditionDate: _d(2026, 7, 18), terrainDifficulty: .technical),
        KnownRace(name: "Eiger Ultra Trail E16", shortName: "E16",
                  distanceKm: 16, elevationGainM: 1100, elevationLossM: 1100, country: "Switzerland",
                  nextEditionDate: _d(2026, 7, 18), terrainDifficulty: .technical),
        KnownRace(name: "Swiss Peaks Trail", shortName: nil,
                  distanceKm: 360, elevationGainM: 25000, elevationLossM: 25000, country: "Switzerland",
                  nextEditionDate: _d(2026, 8, 30), terrainDifficulty: .technical),
        KnownRace(name: "Sierre-Zinal", shortName: nil,
                  distanceKm: 31, elevationGainM: 2200, elevationLossM: 900, country: "Switzerland",
                  nextEditionDate: _d(2026, 8, 8), terrainDifficulty: .technical),

        // MARK: France (Mainland)

        KnownRace(name: "Trail des Templiers", shortName: nil,
                  distanceKm: 78, elevationGainM: 3600, elevationLossM: 3600, country: "France",
                  nextEditionDate: _d(2026, 10, 18), terrainDifficulty: .moderate),
        KnownRace(name: "6000D - La Course des Géants", shortName: "6000D",
                  distanceKm: 68, elevationGainM: 3800, elevationLossM: 3800, country: "France",
                  nextEditionDate: _d(2026, 7, 4), terrainDifficulty: .moderate),
        KnownRace(name: "Échappée Belle", shortName: nil,
                  distanceKm: 144, elevationGainM: 11000, elevationLossM: 11000, country: "France",
                  nextEditionDate: _d(2026, 8, 21), terrainDifficulty: .technical),
        KnownRace(name: "Ultra-Trail Côte d'Azur", shortName: "UTCA",
                  distanceKm: 130, elevationGainM: 6600, elevationLossM: 6600, country: "France",
                  nextEditionDate: _d(2026, 2, 7), terrainDifficulty: .moderate),
        KnownRace(name: "Trail du Mont Blanc", shortName: nil,
                  distanceKm: 90, elevationGainM: 6000, elevationLossM: 6000, country: "France",
                  nextEditionDate: _d(2026, 6, 28), terrainDifficulty: .technical),
        KnownRace(name: "Maxi-Race", shortName: nil,
                  distanceKm: 88, elevationGainM: 5200, elevationLossM: 5200, country: "France",
                  nextEditionDate: _d(2026, 5, 30), terrainDifficulty: .moderate),
        KnownRace(name: "SaintéLyon", shortName: nil,
                  distanceKm: 76, elevationGainM: 1800, elevationLossM: 1800, country: "France",
                  nextEditionDate: _d(2026, 11, 29), terrainDifficulty: .easy),
        KnownRace(name: "Marathon du Mont-Blanc 42K", shortName: "MMB 42K",
                  distanceKm: 42, elevationGainM: 2730, elevationLossM: 2730, country: "France",
                  nextEditionDate: _d(2026, 6, 26), terrainDifficulty: .technical),
        KnownRace(name: "90km du Mont-Blanc", shortName: "90K MdMB",
                  distanceKm: 90, elevationGainM: 6000, elevationLossM: 6000, country: "France",
                  nextEditionDate: _d(2026, 6, 26), terrainDifficulty: .technical),
        KnownRace(name: "Kilomètre Vertical du Mont-Blanc", shortName: "KV MdMB",
                  distanceKm: 3.8, elevationGainM: 1000, elevationLossM: 0, country: "France",
                  nextEditionDate: _d(2026, 6, 25), terrainDifficulty: .technical),
        KnownRace(name: "23K du Mont-Blanc", shortName: "23K MdMB",
                  distanceKm: 23, elevationGainM: 1300, elevationLossM: 1300, country: "France",
                  nextEditionDate: _d(2026, 6, 25), terrainDifficulty: .moderate),
        KnownRace(name: "Marathon du Mont-Blanc — The Young Race", shortName: "Young Race MdMB",
                  distanceKm: 13, elevationGainM: 1500, elevationLossM: 1500, country: "France",
                  nextEditionDate: _d(2026, 6, 25), terrainDifficulty: .moderate),
        KnownRace(name: "10K du Mont-Blanc", shortName: "10K MdMB",
                  distanceKm: 10, elevationGainM: 500, elevationLossM: 500, country: "France",
                  nextEditionDate: _d(2026, 6, 25), terrainDifficulty: .easy),
        KnownRace(name: "EcoTrail de Paris 80K", shortName: "EcoTrail",
                  distanceKm: 80, elevationGainM: 1600, elevationLossM: 1600, country: "France",
                  nextEditionDate: _d(2026, 3, 21), terrainDifficulty: .easy),
        KnownRace(name: "Ultra-Trail du Vercors 100 Miles", shortName: "UTV",
                  distanceKm: 160, elevationGainM: 9500, elevationLossM: 9500, country: "France",
                  nextEditionDate: _d(2026, 6, 13), terrainDifficulty: .technical),

        // MARK: Morocco

        KnownRace(name: "Marathon des Sables", shortName: "MDS",
                  distanceKm: 250, elevationGainM: 2000, elevationLossM: 2000, country: "Morocco",
                  nextEditionDate: _d(2026, 4, 3), terrainDifficulty: .easy),

        // MARK: Turkey & Greece

        KnownRace(name: "Cappadocia Ultra Trail", shortName: "CUTM",
                  distanceKm: 110, elevationGainM: 3500, elevationLossM: 3500, country: "Turkey",
                  nextEditionDate: _d(2026, 10, 17), terrainDifficulty: .moderate),
        KnownRace(name: "Olympus Mythical Trail", shortName: nil,
                  distanceKm: 100, elevationGainM: 6500, elevationLossM: 6500, country: "Greece",
                  nextEditionDate: _d(2026, 6, 20), terrainDifficulty: .technical),

        // MARK: Iceland

        KnownRace(name: "Laugavegur Ultra Marathon", shortName: nil,
                  distanceKm: 55, elevationGainM: 1600, elevationLossM: 1600, country: "Iceland",
                  nextEditionDate: _d(2026, 7, 18), terrainDifficulty: .easy),

        // MARK: UK

        KnownRace(name: "Ultra-Trail Snowdonia", shortName: nil,
                  distanceKm: 100, elevationGainM: 5500, elevationLossM: 5500, country: "UK",
                  nextEditionDate: _d(2026, 5, 9), terrainDifficulty: .moderate),
        KnownRace(name: "Lakeland 100", shortName: nil,
                  distanceKm: 161, elevationGainM: 6300, elevationLossM: 6300, country: "UK",
                  nextEditionDate: _d(2026, 7, 24), terrainDifficulty: .moderate),
        KnownRace(name: "Dragon's Back Race", shortName: nil,
                  distanceKm: 380, elevationGainM: 17000, elevationLossM: 17000, country: "UK",
                  nextEditionDate: _d(2026, 6, 1), terrainDifficulty: .moderate),

        // MARK: Norway

        KnownRace(name: "Tromsø SkyRace", shortName: nil,
                  distanceKm: 57, elevationGainM: 4800, elevationLossM: 4800, country: "Norway",
                  nextEditionDate: _d(2026, 8, 1), terrainDifficulty: .technical),

        // MARK: Andorra

        KnownRace(name: "Ronda dels Cims", shortName: nil,
                  distanceKm: 170, elevationGainM: 13500, elevationLossM: 13500, country: "Andorra",
                  nextEditionDate: _d(2026, 6, 20), terrainDifficulty: .technical),

        // MARK: Portugal

        KnownRace(name: "Madeira Island Ultra Trail 115K", shortName: "MIUT",
                  distanceKm: 115, elevationGainM: 7200, elevationLossM: 7200, country: "Portugal",
                  nextEditionDate: _d(2026, 4, 25), terrainDifficulty: .technical),
        KnownRace(name: "Grand Trail de Porto 70K", shortName: nil,
                  distanceKm: 70, elevationGainM: 3200, elevationLossM: 3200, country: "Portugal",
                  nextEditionDate: _d(2026, 3, 28), terrainDifficulty: .moderate),

        // MARK: Austria

        KnownRace(name: "Mozart 100", shortName: nil,
                  distanceKm: 100, elevationGainM: 4800, elevationLossM: 4800, country: "Austria",
                  nextEditionDate: _d(2026, 6, 20), terrainDifficulty: .moderate),

        // MARK: Croatia

        KnownRace(name: "Istria 100 by UTMB", shortName: "Istria 100",
                  distanceKm: 100, elevationGainM: 5200, elevationLossM: 5200, country: "Croatia",
                  nextEditionDate: _d(2026, 4, 10), terrainDifficulty: .moderate),
    ]
}
