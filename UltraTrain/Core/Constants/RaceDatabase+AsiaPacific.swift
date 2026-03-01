import Foundation

// MARK: - Asia & Pacific

extension RaceDatabase {

    static let asiaPacific: [KnownRace] = [

        // MARK: Hong Kong

        KnownRace(name: "Hong Kong 100", shortName: "HK100",
                  distanceKm: 100, elevationGainM: 4700, elevationLossM: 4700, country: "Hong Kong"),
        KnownRace(name: "Ultra-Trail Tai Mo Shan", shortName: "UTTMS",
                  distanceKm: 162, elevationGainM: 8200, elevationLossM: 8200, country: "Hong Kong"),
        KnownRace(name: "Oxfam Trailwalker Hong Kong", shortName: nil,
                  distanceKm: 100, elevationGainM: 4700, elevationLossM: 4700, country: "Hong Kong"),

        // MARK: New Zealand

        KnownRace(name: "Tarawera Ultramarathon", shortName: nil,
                  distanceKm: 102, elevationGainM: 2600, elevationLossM: 2600, country: "New Zealand"),

        // MARK: Australia

        KnownRace(name: "Ultra-Trail Kosciuszko", shortName: nil,
                  distanceKm: 100, elevationGainM: 4000, elevationLossM: 4000, country: "Australia"),
    ]
}
