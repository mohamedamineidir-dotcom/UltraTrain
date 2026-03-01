import Foundation

// MARK: - Europe

extension RaceDatabase {

    static let europe: [KnownRace] = [

        // MARK: France (Réunion)

        KnownRace(name: "Diagonale des Fous", shortName: "Grand Raid",
                  distanceKm: 165, elevationGainM: 9576, elevationLossM: 9576, country: "France (Réunion)"),
        KnownRace(name: "Trail de Bourbon", shortName: nil,
                  distanceKm: 111, elevationGainM: 6433, elevationLossM: 6433, country: "France (Réunion)"),
        KnownRace(name: "Mascareignes", shortName: nil,
                  distanceKm: 65, elevationGainM: 3505, elevationLossM: 3505, country: "France (Réunion)"),
        KnownRace(name: "Grand Trail de la Réunion", shortName: nil,
                  distanceKm: 165, elevationGainM: 9576, elevationLossM: 9576, country: "France (Réunion)"),

        // MARK: Italy

        KnownRace(name: "Tor des Géants", shortName: "TDG",
                  distanceKm: 330, elevationGainM: 24000, elevationLossM: 24000, country: "Italy"),
        KnownRace(name: "Tor des Glaciers", shortName: nil,
                  distanceKm: 450, elevationGainM: 32000, elevationLossM: 32000, country: "Italy"),

        // MARK: Spain

        KnownRace(name: "Transvulcania", shortName: nil,
                  distanceKm: 74, elevationGainM: 4350, elevationLossM: 4350, country: "Spain"),
        KnownRace(name: "Zegama-Aizkorri Marathon", shortName: "Zegama",
                  distanceKm: 42, elevationGainM: 2736, elevationLossM: 2736, country: "Spain"),
        KnownRace(name: "Gran Trail Peñalara 110K", shortName: nil,
                  distanceKm: 110, elevationGainM: 5500, elevationLossM: 5500, country: "Spain"),
        KnownRace(name: "Gran Trail Peñalara 60K", shortName: nil,
                  distanceKm: 60, elevationGainM: 3000, elevationLossM: 3000, country: "Spain"),
        KnownRace(name: "Ultra Sierra Nevada", shortName: nil,
                  distanceKm: 102, elevationGainM: 5500, elevationLossM: 5500, country: "Spain"),

        // MARK: Switzerland

        KnownRace(name: "Eiger Ultra Trail E101", shortName: "E101",
                  distanceKm: 101, elevationGainM: 6700, elevationLossM: 6700, country: "Switzerland"),
        KnownRace(name: "Eiger Ultra Trail E51", shortName: "E51",
                  distanceKm: 51, elevationGainM: 3400, elevationLossM: 3400, country: "Switzerland"),
        KnownRace(name: "Eiger Ultra Trail E35", shortName: "E35",
                  distanceKm: 35, elevationGainM: 2300, elevationLossM: 2300, country: "Switzerland"),
        KnownRace(name: "Eiger Ultra Trail E16", shortName: "E16",
                  distanceKm: 16, elevationGainM: 1100, elevationLossM: 1100, country: "Switzerland"),
        KnownRace(name: "Swiss Peaks Trail", shortName: nil,
                  distanceKm: 360, elevationGainM: 25000, elevationLossM: 25000, country: "Switzerland"),
        KnownRace(name: "Sierre-Zinal", shortName: nil,
                  distanceKm: 31, elevationGainM: 2200, elevationLossM: 900, country: "Switzerland"),

        // MARK: France (Mainland)

        KnownRace(name: "Trail des Templiers", shortName: nil,
                  distanceKm: 78, elevationGainM: 3600, elevationLossM: 3600, country: "France"),
        KnownRace(name: "6000D - La Course des Géants", shortName: "6000D",
                  distanceKm: 68, elevationGainM: 3800, elevationLossM: 3800, country: "France"),
        KnownRace(name: "Échappée Belle", shortName: nil,
                  distanceKm: 144, elevationGainM: 11000, elevationLossM: 11000, country: "France"),
        KnownRace(name: "Ultra-Trail Côte d'Azur", shortName: "UTCA",
                  distanceKm: 130, elevationGainM: 6600, elevationLossM: 6600, country: "France"),
        KnownRace(name: "Trail du Mont Blanc", shortName: nil,
                  distanceKm: 90, elevationGainM: 6000, elevationLossM: 6000, country: "France"),
        KnownRace(name: "Maxi-Race", shortName: nil,
                  distanceKm: 88, elevationGainM: 5200, elevationLossM: 5200, country: "France"),
        KnownRace(name: "SaintéLyon", shortName: nil,
                  distanceKm: 76, elevationGainM: 1800, elevationLossM: 1800, country: "France"),

        // MARK: Morocco

        KnownRace(name: "Marathon des Sables", shortName: "MDS",
                  distanceKm: 250, elevationGainM: 2000, elevationLossM: 2000, country: "Morocco"),

        // MARK: Turkey & Greece

        KnownRace(name: "Cappadocia Ultra Trail", shortName: "CUTM",
                  distanceKm: 110, elevationGainM: 3500, elevationLossM: 3500, country: "Turkey"),
        KnownRace(name: "Olympus Mythical Trail", shortName: nil,
                  distanceKm: 100, elevationGainM: 6500, elevationLossM: 6500, country: "Greece"),

        // MARK: Iceland

        KnownRace(name: "Laugavegur Ultra Marathon", shortName: nil,
                  distanceKm: 55, elevationGainM: 1600, elevationLossM: 1600, country: "Iceland"),

        // MARK: UK

        KnownRace(name: "Ultra-Trail Snowdonia", shortName: nil,
                  distanceKm: 100, elevationGainM: 5500, elevationLossM: 5500, country: "UK"),
        KnownRace(name: "Lakeland 100", shortName: nil,
                  distanceKm: 161, elevationGainM: 6300, elevationLossM: 6300, country: "UK"),
        KnownRace(name: "Dragon's Back Race", shortName: nil,
                  distanceKm: 380, elevationGainM: 17000, elevationLossM: 17000, country: "UK"),

        // MARK: Norway

        KnownRace(name: "Tromsø SkyRace", shortName: nil,
                  distanceKm: 57, elevationGainM: 4800, elevationLossM: 4800, country: "Norway"),

        // MARK: Andorra

        KnownRace(name: "Ronda dels Cims", shortName: nil,
                  distanceKm: 170, elevationGainM: 13500, elevationLossM: 13500, country: "Andorra"),
    ]
}
