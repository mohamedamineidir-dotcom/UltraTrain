import Foundation

enum RaceDatabase {

    static let races: [KnownRace] = [
        // MARK: - UTMB Series
        KnownRace(name: "Ultra-Trail du Mont-Blanc", shortName: "UTMB", distanceKm: 171, elevationGainM: 10000, elevationLossM: 10000, country: "France"),
        KnownRace(name: "Courmayeur-Champex-Chamonix", shortName: "CCC", distanceKm: 101, elevationGainM: 6100, elevationLossM: 6100, country: "France"),
        KnownRace(name: "Sur les Traces des Ducs de Savoie", shortName: "TDS", distanceKm: 145, elevationGainM: 9100, elevationLossM: 9100, country: "France"),
        KnownRace(name: "Orsières-Champex-Chamonix", shortName: "OCC", distanceKm: 55, elevationGainM: 3500, elevationLossM: 3500, country: "France"),
        KnownRace(name: "Martigny-Combe-Champex", shortName: "MCC", distanceKm: 40, elevationGainM: 2300, elevationLossM: 2300, country: "Switzerland"),
        KnownRace(name: "ETC – Évasion Trail du Courmayeur", shortName: "ETC", distanceKm: 15, elevationGainM: 1000, elevationLossM: 1000, country: "Italy"),

        // MARK: - Réunion
        KnownRace(name: "Diagonale des Fous", shortName: "Grand Raid", distanceKm: 165, elevationGainM: 9576, elevationLossM: 9576, country: "France (Réunion)"),
        KnownRace(name: "Trail de Bourbon", shortName: nil, distanceKm: 111, elevationGainM: 6433, elevationLossM: 6433, country: "France (Réunion)"),
        KnownRace(name: "Mascareignes", shortName: nil, distanceKm: 65, elevationGainM: 3505, elevationLossM: 3505, country: "France (Réunion)"),

        // MARK: - USA Iconic
        KnownRace(name: "Western States 100", shortName: "WSER", distanceKm: 161, elevationGainM: 5500, elevationLossM: 7000, country: "USA"),
        KnownRace(name: "Hardrock Hundred", shortName: "Hardrock 100", distanceKm: 161, elevationGainM: 10000, elevationLossM: 10000, country: "USA"),
        KnownRace(name: "Leadville Trail 100", shortName: "Leadville 100", distanceKm: 161, elevationGainM: 4800, elevationLossM: 4800, country: "USA"),
        KnownRace(name: "Barkley Marathons", shortName: "Barkley", distanceKm: 210, elevationGainM: 18000, elevationLossM: 18000, country: "USA"),
        KnownRace(name: "UTMB World Series Canyons 100K", shortName: "Canyons 100K", distanceKm: 100, elevationGainM: 4900, elevationLossM: 4900, country: "USA"),
        KnownRace(name: "Javelina Jundred", shortName: "Javelina 100", distanceKm: 161, elevationGainM: 1800, elevationLossM: 1800, country: "USA"),
        KnownRace(name: "HURT 100", shortName: nil, distanceKm: 161, elevationGainM: 7500, elevationLossM: 7500, country: "USA"),
        KnownRace(name: "Bigfoot 200", shortName: nil, distanceKm: 330, elevationGainM: 14000, elevationLossM: 14000, country: "USA"),

        // MARK: - Italy
        KnownRace(name: "Tor des Géants", shortName: "TDG", distanceKm: 330, elevationGainM: 24000, elevationLossM: 24000, country: "Italy"),
        KnownRace(name: "Lavaredo Ultra Trail", shortName: "LUT", distanceKm: 120, elevationGainM: 5850, elevationLossM: 5850, country: "Italy"),
        KnownRace(name: "Tor des Glaciers", shortName: nil, distanceKm: 450, elevationGainM: 32000, elevationLossM: 32000, country: "Italy"),

        // MARK: - Spain / Canary Islands
        KnownRace(name: "Transgrancanaria", shortName: "TGC", distanceKm: 128, elevationGainM: 7500, elevationLossM: 7500, country: "Spain"),
        KnownRace(name: "Transvulcania", shortName: nil, distanceKm: 74, elevationGainM: 4350, elevationLossM: 4350, country: "Spain"),
        KnownRace(name: "Penyagolosa Trails", shortName: nil, distanceKm: 109, elevationGainM: 5400, elevationLossM: 5400, country: "Spain"),
        KnownRace(name: "Ultra Pirineu", shortName: nil, distanceKm: 100, elevationGainM: 6400, elevationLossM: 6400, country: "Spain"),
        KnownRace(name: "Zegama-Aizkorri Marathon", shortName: "Zegama", distanceKm: 42, elevationGainM: 2736, elevationLossM: 2736, country: "Spain"),

        // MARK: - Switzerland
        KnownRace(name: "Eiger Ultra Trail", shortName: "E101", distanceKm: 101, elevationGainM: 6700, elevationLossM: 6700, country: "Switzerland"),
        KnownRace(name: "Swiss Peaks Trail", shortName: nil, distanceKm: 360, elevationGainM: 25000, elevationLossM: 25000, country: "Switzerland"),
        KnownRace(name: "Sierre-Zinal", shortName: nil, distanceKm: 31, elevationGainM: 2200, elevationLossM: 900, country: "Switzerland"),

        // MARK: - Portugal
        KnownRace(name: "Madeira Island Ultra Trail", shortName: "MIUT", distanceKm: 115, elevationGainM: 7200, elevationLossM: 7200, country: "Portugal"),

        // MARK: - Africa / Morocco
        KnownRace(name: "Marathon des Sables", shortName: "MDS", distanceKm: 250, elevationGainM: 2000, elevationLossM: 2000, country: "Morocco"),

        // MARK: - Asia
        KnownRace(name: "Hong Kong 100", shortName: "HK100", distanceKm: 100, elevationGainM: 4700, elevationLossM: 4700, country: "Hong Kong"),
        KnownRace(name: "Ultra-Trail Mt. Fuji", shortName: "UTMF", distanceKm: 165, elevationGainM: 7942, elevationLossM: 7942, country: "Japan"),
        KnownRace(name: "Ultra-Trail Tai Mo Shan", shortName: "UTTMS", distanceKm: 162, elevationGainM: 8200, elevationLossM: 8200, country: "Hong Kong"),

        // MARK: - Oceania
        KnownRace(name: "Ultra-Trail Australia", shortName: "UTA", distanceKm: 100, elevationGainM: 4400, elevationLossM: 4400, country: "Australia"),
        KnownRace(name: "Tarawera Ultramarathon", shortName: nil, distanceKm: 102, elevationGainM: 2600, elevationLossM: 2600, country: "New Zealand"),

        // MARK: - France (Other)
        KnownRace(name: "Trail des Templiers", shortName: nil, distanceKm: 78, elevationGainM: 3600, elevationLossM: 3600, country: "France"),
        KnownRace(name: "6000D – La Course des Géants", shortName: "6000D", distanceKm: 68, elevationGainM: 3800, elevationLossM: 3800, country: "France"),
        KnownRace(name: "Échappée Belle", shortName: nil, distanceKm: 144, elevationGainM: 11000, elevationLossM: 11000, country: "France"),
        KnownRace(name: "Ultra-Trail Côte d'Azur", shortName: "UTCA", distanceKm: 130, elevationGainM: 6600, elevationLossM: 6600, country: "France"),
        KnownRace(name: "Grand Trail des Templiers", shortName: nil, distanceKm: 78, elevationGainM: 3600, elevationLossM: 3600, country: "France"),
        KnownRace(name: "Trail du Mont Blanc", shortName: nil, distanceKm: 90, elevationGainM: 6000, elevationLossM: 6000, country: "France"),
        KnownRace(name: "Maxi-Race", shortName: nil, distanceKm: 88, elevationGainM: 5200, elevationLossM: 5200, country: "France"),
        KnownRace(name: "SaintéLyon", shortName: nil, distanceKm: 76, elevationGainM: 1800, elevationLossM: 1800, country: "France"),
        KnownRace(name: "Grand Trail de la Réunion", shortName: nil, distanceKm: 165, elevationGainM: 9576, elevationLossM: 9576, country: "France (Réunion)"),

        // MARK: - Turkey / Greece / Eastern Europe
        KnownRace(name: "Cappadocia Ultra Trail", shortName: "CUTM", distanceKm: 110, elevationGainM: 3500, elevationLossM: 3500, country: "Turkey"),
        KnownRace(name: "Olympus Mythical Trail", shortName: nil, distanceKm: 100, elevationGainM: 6500, elevationLossM: 6500, country: "Greece"),

        // MARK: - Scandinavia
        KnownRace(name: "Laugavegur Ultra Marathon", shortName: nil, distanceKm: 55, elevationGainM: 1600, elevationLossM: 1600, country: "Iceland"),

        // MARK: - South America
        KnownRace(name: "Ultra-Trail Torres del Paine", shortName: "UTTP", distanceKm: 80, elevationGainM: 4300, elevationLossM: 4300, country: "Chile"),
        KnownRace(name: "Patagonia Run", shortName: nil, distanceKm: 100, elevationGainM: 4000, elevationLossM: 4000, country: "Argentina"),

        // MARK: - UK
        KnownRace(name: "Ultra-Trail Snowdonia", shortName: nil, distanceKm: 100, elevationGainM: 5500, elevationLossM: 5500, country: "UK"),
        KnownRace(name: "Lakeland 100", shortName: nil, distanceKm: 161, elevationGainM: 6300, elevationLossM: 6300, country: "UK"),
        KnownRace(name: "Dragon's Back Race", shortName: nil, distanceKm: 380, elevationGainM: 17000, elevationLossM: 17000, country: "UK"),
    ]

    static func search(query: String) -> [KnownRace] {
        guard !query.isEmpty else { return [] }
        let lowered = query.lowercased()
        return races.filter { race in
            race.name.lowercased().contains(lowered)
                || race.shortName?.lowercased().contains(lowered) == true
                || race.country.lowercased().contains(lowered)
        }
    }
}
