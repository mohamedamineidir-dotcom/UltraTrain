import Foundation

// swiftlint:disable:next identifier_name
private func _d(_ year: Int, _ month: Int, _ day: Int) -> Date {
    DateComponents(calendar: .current, year: year, month: month, day: day).date!
}

// MARK: - Asia & Pacific

extension RaceDatabase {

    static let asiaPacific: [KnownRace] = [

        // MARK: Hong Kong

        KnownRace(name: "Hong Kong 100", shortName: "HK100",
                  distanceKm: 100, elevationGainM: 4700, elevationLossM: 4700, country: "Hong Kong",
                  nextEditionDate: _d(2026, 1, 17)),
        KnownRace(name: "Ultra-Trail Tai Mo Shan", shortName: "UTTMS",
                  distanceKm: 162, elevationGainM: 8200, elevationLossM: 8200, country: "Hong Kong",
                  nextEditionDate: _d(2026, 3, 7)),
        KnownRace(name: "Oxfam Trailwalker Hong Kong", shortName: nil,
                  distanceKm: 100, elevationGainM: 4700, elevationLossM: 4700, country: "Hong Kong",
                  nextEditionDate: _d(2026, 11, 14)),

        // MARK: New Zealand

        KnownRace(name: "Tarawera Ultramarathon", shortName: nil,
                  distanceKm: 102, elevationGainM: 2600, elevationLossM: 2600, country: "New Zealand",
                  nextEditionDate: _d(2026, 2, 7)),

        // MARK: Australia

        KnownRace(name: "Ultra-Trail Kosciuszko", shortName: nil,
                  distanceKm: 100, elevationGainM: 4000, elevationLossM: 4000, country: "Australia",
                  nextEditionDate: _d(2026, 12, 4)),
    ]
}
