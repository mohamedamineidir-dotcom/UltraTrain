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
                  nextEditionDate: _d(2026, 10, 22)),
        KnownRace(name: "Trail de Bourbon", shortName: nil,
                  distanceKm: 111, elevationGainM: 6433, elevationLossM: 6433, country: "France (Réunion)",
                  nextEditionDate: _d(2026, 10, 23)),
        KnownRace(name: "Mascareignes", shortName: nil,
                  distanceKm: 65, elevationGainM: 3505, elevationLossM: 3505, country: "France (Réunion)",
                  nextEditionDate: _d(2026, 10, 23)),
        KnownRace(name: "Grand Trail de la Réunion", shortName: nil,
                  distanceKm: 165, elevationGainM: 9576, elevationLossM: 9576, country: "France (Réunion)",
                  nextEditionDate: _d(2026, 10, 22)),

        // MARK: Italy

        KnownRace(name: "Tor des Géants", shortName: "TDG",
                  distanceKm: 330, elevationGainM: 24000, elevationLossM: 24000, country: "Italy",
                  nextEditionDate: _d(2026, 9, 6)),
        KnownRace(name: "Tor des Glaciers", shortName: nil,
                  distanceKm: 450, elevationGainM: 32000, elevationLossM: 32000, country: "Italy",
                  nextEditionDate: _d(2026, 9, 1)),

        // MARK: Spain

        KnownRace(name: "Transvulcania", shortName: nil,
                  distanceKm: 74, elevationGainM: 4350, elevationLossM: 4350, country: "Spain",
                  nextEditionDate: _d(2026, 5, 9)),
        KnownRace(name: "Zegama-Aizkorri Marathon", shortName: "Zegama",
                  distanceKm: 42, elevationGainM: 2736, elevationLossM: 2736, country: "Spain",
                  nextEditionDate: _d(2026, 5, 24)),
        KnownRace(name: "Gran Trail Peñalara 110K", shortName: nil,
                  distanceKm: 110, elevationGainM: 5500, elevationLossM: 5500, country: "Spain",
                  nextEditionDate: _d(2026, 6, 27)),
        KnownRace(name: "Gran Trail Peñalara 60K", shortName: nil,
                  distanceKm: 60, elevationGainM: 3000, elevationLossM: 3000, country: "Spain",
                  nextEditionDate: _d(2026, 6, 27)),
        KnownRace(name: "Ultra Sierra Nevada", shortName: nil,
                  distanceKm: 102, elevationGainM: 5500, elevationLossM: 5500, country: "Spain",
                  nextEditionDate: _d(2026, 7, 4)),

        // MARK: Switzerland

        KnownRace(name: "Eiger Ultra Trail E101", shortName: "E101",
                  distanceKm: 101, elevationGainM: 6700, elevationLossM: 6700, country: "Switzerland",
                  nextEditionDate: _d(2026, 7, 18)),
        KnownRace(name: "Eiger Ultra Trail E51", shortName: "E51",
                  distanceKm: 51, elevationGainM: 3400, elevationLossM: 3400, country: "Switzerland",
                  nextEditionDate: _d(2026, 7, 18)),
        KnownRace(name: "Eiger Ultra Trail E35", shortName: "E35",
                  distanceKm: 35, elevationGainM: 2300, elevationLossM: 2300, country: "Switzerland",
                  nextEditionDate: _d(2026, 7, 18)),
        KnownRace(name: "Eiger Ultra Trail E16", shortName: "E16",
                  distanceKm: 16, elevationGainM: 1100, elevationLossM: 1100, country: "Switzerland",
                  nextEditionDate: _d(2026, 7, 18)),
        KnownRace(name: "Swiss Peaks Trail", shortName: nil,
                  distanceKm: 360, elevationGainM: 25000, elevationLossM: 25000, country: "Switzerland",
                  nextEditionDate: _d(2026, 8, 30)),
        KnownRace(name: "Sierre-Zinal", shortName: nil,
                  distanceKm: 31, elevationGainM: 2200, elevationLossM: 900, country: "Switzerland",
                  nextEditionDate: _d(2026, 8, 8)),

        // MARK: France (Mainland)

        KnownRace(name: "Trail des Templiers", shortName: nil,
                  distanceKm: 78, elevationGainM: 3600, elevationLossM: 3600, country: "France",
                  nextEditionDate: _d(2026, 10, 18)),
        KnownRace(name: "6000D - La Course des Géants", shortName: "6000D",
                  distanceKm: 68, elevationGainM: 3800, elevationLossM: 3800, country: "France",
                  nextEditionDate: _d(2026, 7, 4)),
        KnownRace(name: "Échappée Belle", shortName: nil,
                  distanceKm: 144, elevationGainM: 11000, elevationLossM: 11000, country: "France",
                  nextEditionDate: _d(2026, 8, 21)),
        KnownRace(name: "Ultra-Trail Côte d'Azur", shortName: "UTCA",
                  distanceKm: 130, elevationGainM: 6600, elevationLossM: 6600, country: "France",
                  nextEditionDate: _d(2026, 2, 7)),
        KnownRace(name: "Trail du Mont Blanc", shortName: nil,
                  distanceKm: 90, elevationGainM: 6000, elevationLossM: 6000, country: "France",
                  nextEditionDate: _d(2026, 6, 28)),
        KnownRace(name: "Maxi-Race", shortName: nil,
                  distanceKm: 88, elevationGainM: 5200, elevationLossM: 5200, country: "France",
                  nextEditionDate: _d(2026, 5, 30)),
        KnownRace(name: "SaintéLyon", shortName: nil,
                  distanceKm: 76, elevationGainM: 1800, elevationLossM: 1800, country: "France",
                  nextEditionDate: _d(2026, 11, 29)),

        // MARK: Morocco

        KnownRace(name: "Marathon des Sables", shortName: "MDS",
                  distanceKm: 250, elevationGainM: 2000, elevationLossM: 2000, country: "Morocco",
                  nextEditionDate: _d(2026, 4, 3)),

        // MARK: Turkey & Greece

        KnownRace(name: "Cappadocia Ultra Trail", shortName: "CUTM",
                  distanceKm: 110, elevationGainM: 3500, elevationLossM: 3500, country: "Turkey",
                  nextEditionDate: _d(2026, 10, 17)),
        KnownRace(name: "Olympus Mythical Trail", shortName: nil,
                  distanceKm: 100, elevationGainM: 6500, elevationLossM: 6500, country: "Greece",
                  nextEditionDate: _d(2026, 6, 20)),

        // MARK: Iceland

        KnownRace(name: "Laugavegur Ultra Marathon", shortName: nil,
                  distanceKm: 55, elevationGainM: 1600, elevationLossM: 1600, country: "Iceland",
                  nextEditionDate: _d(2026, 7, 18)),

        // MARK: UK

        KnownRace(name: "Ultra-Trail Snowdonia", shortName: nil,
                  distanceKm: 100, elevationGainM: 5500, elevationLossM: 5500, country: "UK",
                  nextEditionDate: _d(2026, 5, 9)),
        KnownRace(name: "Lakeland 100", shortName: nil,
                  distanceKm: 161, elevationGainM: 6300, elevationLossM: 6300, country: "UK",
                  nextEditionDate: _d(2026, 7, 24)),
        KnownRace(name: "Dragon's Back Race", shortName: nil,
                  distanceKm: 380, elevationGainM: 17000, elevationLossM: 17000, country: "UK",
                  nextEditionDate: _d(2026, 6, 1)),

        // MARK: Norway

        KnownRace(name: "Tromsø SkyRace", shortName: nil,
                  distanceKm: 57, elevationGainM: 4800, elevationLossM: 4800, country: "Norway",
                  nextEditionDate: _d(2026, 8, 1)),

        // MARK: Andorra

        KnownRace(name: "Ronda dels Cims", shortName: nil,
                  distanceKm: 170, elevationGainM: 13500, elevationLossM: 13500, country: "Andorra",
                  nextEditionDate: _d(2026, 6, 20)),
    ]
}
