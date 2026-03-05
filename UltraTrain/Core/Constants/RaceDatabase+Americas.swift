import Foundation

// swiftlint:disable:next identifier_name
private func _d(_ year: Int, _ month: Int, _ day: Int) -> Date {
    DateComponents(calendar: .current, year: year, month: month, day: day).date!
}

// MARK: - Americas (USA & South America)

extension RaceDatabase {

    static let americas: [KnownRace] = [

        // MARK: USA - Iconic Ultras

        KnownRace(name: "Hardrock Hundred", shortName: "Hardrock 100",
                  distanceKm: 161, elevationGainM: 10000, elevationLossM: 10000, country: "USA",
                  nextEditionDate: _d(2026, 7, 10)),
        KnownRace(name: "Leadville Trail 100", shortName: "Leadville 100",
                  distanceKm: 161, elevationGainM: 4800, elevationLossM: 4800, country: "USA",
                  nextEditionDate: _d(2026, 8, 15)),
        KnownRace(name: "Barkley Marathons", shortName: "Barkley",
                  distanceKm: 210, elevationGainM: 18000, elevationLossM: 18000, country: "USA",
                  nextEditionDate: _d(2026, 3, 28)),
        KnownRace(name: "Javelina Jundred", shortName: "Javelina 100",
                  distanceKm: 161, elevationGainM: 1800, elevationLossM: 1800, country: "USA",
                  nextEditionDate: _d(2026, 10, 31)),
        KnownRace(name: "HURT 100", shortName: nil,
                  distanceKm: 161, elevationGainM: 7500, elevationLossM: 7500, country: "USA",
                  nextEditionDate: _d(2026, 1, 17)),
        KnownRace(name: "Bigfoot 200", shortName: nil,
                  distanceKm: 330, elevationGainM: 14000, elevationLossM: 14000, country: "USA",
                  nextEditionDate: _d(2026, 8, 7)),

        // MARK: USA - 200+ Milers

        KnownRace(name: "Moab 240", shortName: nil,
                  distanceKm: 386, elevationGainM: 9000, elevationLossM: 9000, country: "USA",
                  nextEditionDate: _d(2026, 10, 9)),
        KnownRace(name: "Tahoe 200", shortName: nil,
                  distanceKm: 330, elevationGainM: 12000, elevationLossM: 12000, country: "USA",
                  nextEditionDate: _d(2026, 7, 31)),
        KnownRace(name: "Cocodona 250", shortName: nil,
                  distanceKm: 402, elevationGainM: 12000, elevationLossM: 12000, country: "USA",
                  nextEditionDate: _d(2026, 5, 4)),

        // MARK: USA - Classic 100 Milers

        KnownRace(name: "Badwater 135", shortName: nil,
                  distanceKm: 217, elevationGainM: 4450, elevationLossM: 1859, country: "USA",
                  nextEditionDate: _d(2026, 7, 13)),
        KnownRace(name: "Bear 100", shortName: nil,
                  distanceKm: 161, elevationGainM: 6700, elevationLossM: 6700, country: "USA",
                  nextEditionDate: _d(2026, 9, 25)),
        KnownRace(name: "Superior 100", shortName: nil,
                  distanceKm: 161, elevationGainM: 6000, elevationLossM: 6000, country: "USA",
                  nextEditionDate: _d(2026, 9, 11)),
        KnownRace(name: "Wasatch 100", shortName: nil,
                  distanceKm: 161, elevationGainM: 8000, elevationLossM: 8000, country: "USA",
                  nextEditionDate: _d(2026, 9, 4)),
        KnownRace(name: "Angeles Crest 100", shortName: nil,
                  distanceKm: 161, elevationGainM: 6400, elevationLossM: 6400, country: "USA",
                  nextEditionDate: _d(2026, 8, 1)),
        KnownRace(name: "Run Rabbit Run 100", shortName: nil,
                  distanceKm: 161, elevationGainM: 6000, elevationLossM: 6000, country: "USA",
                  nextEditionDate: _d(2026, 9, 18)),

        // MARK: USA - Shorter Ultras

        KnownRace(name: "Rim to Rim to Rim Grand Canyon", shortName: "R2R2R",
                  distanceKm: 68, elevationGainM: 3200, elevationLossM: 3200, country: "USA",
                  nextEditionDate: nil),
        KnownRace(name: "Pikes Peak Marathon", shortName: nil,
                  distanceKm: 42, elevationGainM: 2380, elevationLossM: 2380, country: "USA",
                  nextEditionDate: _d(2026, 8, 16)),

        // MARK: South America

        KnownRace(name: "Ultra-Trail Torres del Paine", shortName: "UTTP",
                  distanceKm: 80, elevationGainM: 4300, elevationLossM: 4300, country: "Chile",
                  nextEditionDate: _d(2026, 9, 26)),
        KnownRace(name: "Patagonia Run", shortName: nil,
                  distanceKm: 100, elevationGainM: 4000, elevationLossM: 4000, country: "Argentina",
                  nextEditionDate: _d(2026, 4, 11)),
        KnownRace(name: "Ultra Fiord", shortName: nil,
                  distanceKm: 100, elevationGainM: 4000, elevationLossM: 4000, country: "Chile",
                  nextEditionDate: _d(2026, 5, 2)),
    ]
}
