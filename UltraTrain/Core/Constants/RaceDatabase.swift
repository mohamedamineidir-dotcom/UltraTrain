import Foundation

enum RaceDatabase {

    static let races: [KnownRace] =
        worldTrailMajors
        + utmbWorldSeries
        + americas
        + europe
        + asiaPacific

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
