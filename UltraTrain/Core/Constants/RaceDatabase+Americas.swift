import Foundation

// MARK: - Americas (USA & South America)

extension RaceDatabase {

    static let americas: [KnownRace] = [

        // MARK: USA - Iconic Ultras

        KnownRace(name: "Hardrock Hundred", shortName: "Hardrock 100",
                  distanceKm: 161, elevationGainM: 10000, elevationLossM: 10000, country: "USA"),
        KnownRace(name: "Leadville Trail 100", shortName: "Leadville 100",
                  distanceKm: 161, elevationGainM: 4800, elevationLossM: 4800, country: "USA"),
        KnownRace(name: "Barkley Marathons", shortName: "Barkley",
                  distanceKm: 210, elevationGainM: 18000, elevationLossM: 18000, country: "USA"),
        KnownRace(name: "Javelina Jundred", shortName: "Javelina 100",
                  distanceKm: 161, elevationGainM: 1800, elevationLossM: 1800, country: "USA"),
        KnownRace(name: "HURT 100", shortName: nil,
                  distanceKm: 161, elevationGainM: 7500, elevationLossM: 7500, country: "USA"),
        KnownRace(name: "Bigfoot 200", shortName: nil,
                  distanceKm: 330, elevationGainM: 14000, elevationLossM: 14000, country: "USA"),

        // MARK: USA - 200+ Milers

        KnownRace(name: "Moab 240", shortName: nil,
                  distanceKm: 386, elevationGainM: 9000, elevationLossM: 9000, country: "USA"),
        KnownRace(name: "Tahoe 200", shortName: nil,
                  distanceKm: 330, elevationGainM: 12000, elevationLossM: 12000, country: "USA"),
        KnownRace(name: "Cocodona 250", shortName: nil,
                  distanceKm: 402, elevationGainM: 12000, elevationLossM: 12000, country: "USA"),

        // MARK: USA - Classic 100 Milers

        KnownRace(name: "Badwater 135", shortName: nil,
                  distanceKm: 217, elevationGainM: 4450, elevationLossM: 1859, country: "USA"),
        KnownRace(name: "Bear 100", shortName: nil,
                  distanceKm: 161, elevationGainM: 6700, elevationLossM: 6700, country: "USA"),
        KnownRace(name: "Superior 100", shortName: nil,
                  distanceKm: 161, elevationGainM: 6000, elevationLossM: 6000, country: "USA"),
        KnownRace(name: "Wasatch 100", shortName: nil,
                  distanceKm: 161, elevationGainM: 8000, elevationLossM: 8000, country: "USA"),
        KnownRace(name: "Angeles Crest 100", shortName: nil,
                  distanceKm: 161, elevationGainM: 6400, elevationLossM: 6400, country: "USA"),
        KnownRace(name: "Run Rabbit Run 100", shortName: nil,
                  distanceKm: 161, elevationGainM: 6000, elevationLossM: 6000, country: "USA"),

        // MARK: USA - Shorter Ultras

        KnownRace(name: "Rim to Rim to Rim Grand Canyon", shortName: "R2R2R",
                  distanceKm: 68, elevationGainM: 3200, elevationLossM: 3200, country: "USA"),
        KnownRace(name: "Pikes Peak Marathon", shortName: nil,
                  distanceKm: 42, elevationGainM: 2380, elevationLossM: 2380, country: "USA"),

        // MARK: South America

        KnownRace(name: "Ultra-Trail Torres del Paine", shortName: "UTTP",
                  distanceKm: 80, elevationGainM: 4300, elevationLossM: 4300, country: "Chile"),
        KnownRace(name: "Patagonia Run", shortName: nil,
                  distanceKm: 100, elevationGainM: 4000, elevationLossM: 4000, country: "Argentina"),
        KnownRace(name: "Ultra Fiord", shortName: nil,
                  distanceKm: 100, elevationGainM: 4000, elevationLossM: 4000, country: "Chile"),
    ]
}
