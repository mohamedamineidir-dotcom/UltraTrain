import Foundation

// MARK: - World Trail Majors

extension RaceDatabase {

    static let worldTrailMajors: [KnownRace] = [

        // MARK: UTMB Mont-Blanc (France)

        KnownRace(name: "Ultra-Trail du Mont-Blanc", shortName: "UTMB",
                  distanceKm: 171, elevationGainM: 10000, elevationLossM: 10000, country: "France"),
        KnownRace(name: "Courmayeur-Champex-Chamonix", shortName: "CCC",
                  distanceKm: 101, elevationGainM: 6100, elevationLossM: 6100, country: "France"),
        KnownRace(name: "Sur les Traces des Ducs de Savoie", shortName: "TDS",
                  distanceKm: 145, elevationGainM: 9100, elevationLossM: 9100, country: "France"),
        KnownRace(name: "Orsières-Champex-Chamonix", shortName: "OCC",
                  distanceKm: 55, elevationGainM: 3500, elevationLossM: 3500, country: "France"),
        KnownRace(name: "Martigny-Combe-Champex", shortName: "MCC",
                  distanceKm: 40, elevationGainM: 2300, elevationLossM: 2300, country: "Switzerland"),
        KnownRace(name: "ETC - Évasion Trail du Courmayeur", shortName: "ETC",
                  distanceKm: 15, elevationGainM: 1000, elevationLossM: 1000, country: "Italy"),

        // MARK: Western States 100 (USA)

        KnownRace(name: "Western States 100", shortName: "WSER",
                  distanceKm: 161, elevationGainM: 5500, elevationLossM: 7000, country: "USA"),

        // MARK: Ultra-Trail Cape Town (South Africa)

        KnownRace(name: "Ultra-Trail Cape Town 100K", shortName: "UTCT 100K",
                  distanceKm: 100, elevationGainM: 4300, elevationLossM: 4300, country: "South Africa"),
        KnownRace(name: "Ultra-Trail Cape Town 65K", shortName: "UTCT 65K",
                  distanceKm: 65, elevationGainM: 2500, elevationLossM: 2500, country: "South Africa"),
        KnownRace(name: "Ultra-Trail Cape Town 35K", shortName: "UTCT 35K",
                  distanceKm: 35, elevationGainM: 1200, elevationLossM: 1200, country: "South Africa"),
        KnownRace(name: "Ultra-Trail Cape Town 21K", shortName: "UTCT 21K",
                  distanceKm: 21, elevationGainM: 700, elevationLossM: 700, country: "South Africa"),

        // MARK: Penyagolosa Trails (Spain)

        KnownRace(name: "Penyagolosa Trails MiM", shortName: "MiM",
                  distanceKm: 109, elevationGainM: 5400, elevationLossM: 5400, country: "Spain"),
        KnownRace(name: "Penyagolosa Trails CSP", shortName: "CSP",
                  distanceKm: 62, elevationGainM: 2700, elevationLossM: 2700, country: "Spain"),

        // MARK: Ultra Pirineu (Spain)

        KnownRace(name: "Ultra Pirineu 100K", shortName: nil,
                  distanceKm: 100, elevationGainM: 6400, elevationLossM: 6400, country: "Spain"),
        KnownRace(name: "Ultra Pirineu 68K", shortName: nil,
                  distanceKm: 68, elevationGainM: 4200, elevationLossM: 4200, country: "Spain"),
        KnownRace(name: "Ultra Pirineu 42K", shortName: nil,
                  distanceKm: 42, elevationGainM: 2300, elevationLossM: 2300, country: "Spain"),

        // MARK: TransGranCanaria (Spain)

        KnownRace(name: "TransGranCanaria Classic", shortName: "TGC Classic",
                  distanceKm: 128, elevationGainM: 7500, elevationLossM: 7500, country: "Spain"),
        KnownRace(name: "TransGranCanaria Marathon", shortName: "TGC Marathon",
                  distanceKm: 83, elevationGainM: 4400, elevationLossM: 4400, country: "Spain"),
        KnownRace(name: "TransGranCanaria Starter", shortName: "TGC Starter",
                  distanceKm: 64, elevationGainM: 3100, elevationLossM: 3100, country: "Spain"),
        KnownRace(name: "TransGranCanaria Advanced", shortName: "TGC Advanced",
                  distanceKm: 42, elevationGainM: 2000, elevationLossM: 2000, country: "Spain"),
        KnownRace(name: "TransGranCanaria 30K", shortName: "TGC 30K",
                  distanceKm: 30, elevationGainM: 1400, elevationLossM: 1400, country: "Spain"),

        // MARK: Lavaredo Ultra Trail (Italy)

        KnownRace(name: "Lavaredo Ultra Trail 120K", shortName: "LUT",
                  distanceKm: 120, elevationGainM: 5850, elevationLossM: 5850, country: "Italy"),
        KnownRace(name: "Cortina Trail 80K", shortName: nil,
                  distanceKm: 80, elevationGainM: 4000, elevationLossM: 4000, country: "Italy"),
        KnownRace(name: "Cortina Skyrace 48K", shortName: nil,
                  distanceKm: 48, elevationGainM: 2600, elevationLossM: 2600, country: "Italy"),
        KnownRace(name: "Lavaredo 20K", shortName: nil,
                  distanceKm: 20, elevationGainM: 1100, elevationLossM: 1100, country: "Italy"),

        // MARK: Ultra-Trail Australia

        KnownRace(name: "Ultra-Trail Australia 100K", shortName: "UTA 100",
                  distanceKm: 100, elevationGainM: 4400, elevationLossM: 4400, country: "Australia"),
        KnownRace(name: "Ultra-Trail Australia 50K", shortName: "UTA 50",
                  distanceKm: 50, elevationGainM: 2200, elevationLossM: 2200, country: "Australia"),
        KnownRace(name: "Ultra-Trail Australia 22K", shortName: "UTA 22",
                  distanceKm: 22, elevationGainM: 1000, elevationLossM: 1000, country: "Australia"),

        // MARK: MIUT Madeira (Portugal)

        KnownRace(name: "Madeira Island Ultra Trail", shortName: "MIUT Ultra",
                  distanceKm: 115, elevationGainM: 7200, elevationLossM: 7200, country: "Portugal"),
        KnownRace(name: "MIUT Marathon", shortName: "MIUT 85K",
                  distanceKm: 85, elevationGainM: 4100, elevationLossM: 4100, country: "Portugal"),
        KnownRace(name: "MIUT Mini", shortName: "MIUT 60K",
                  distanceKm: 60, elevationGainM: 3400, elevationLossM: 3400, country: "Portugal"),
        KnownRace(name: "MIUT Trail", shortName: "MIUT 42K",
                  distanceKm: 42, elevationGainM: 2200, elevationLossM: 2200, country: "Portugal"),
        KnownRace(name: "MIUT 16K", shortName: nil,
                  distanceKm: 16, elevationGainM: 900, elevationLossM: 900, country: "Portugal"),

        // MARK: Trail 100 Andorra

        KnownRace(name: "Trail 100 Andorra 112K", shortName: nil,
                  distanceKm: 112, elevationGainM: 6500, elevationLossM: 6500, country: "Andorra"),
        KnownRace(name: "Trail 100 Andorra 60K", shortName: nil,
                  distanceKm: 60, elevationGainM: 3800, elevationLossM: 3800, country: "Andorra"),
        KnownRace(name: "Trail 100 Andorra 40K", shortName: nil,
                  distanceKm: 40, elevationGainM: 2200, elevationLossM: 2200, country: "Andorra"),
    ]
}
