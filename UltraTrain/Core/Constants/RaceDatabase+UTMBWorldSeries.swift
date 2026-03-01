import Foundation

// MARK: - UTMB World Series / By UTMB Circuit

extension RaceDatabase {

    static let utmbWorldSeries: [KnownRace] = [

        // MARK: Nice Côte d'Azur by UTMB (France)

        KnownRace(name: "Nice Côte d'Azur by UTMB 160K", shortName: "NCA 160K",
                  distanceKm: 160, elevationGainM: 9000, elevationLossM: 9000, country: "France"),
        KnownRace(name: "Nice Côte d'Azur by UTMB 100K", shortName: "NCA 100K",
                  distanceKm: 100, elevationGainM: 5500, elevationLossM: 5500, country: "France"),
        KnownRace(name: "Nice Côte d'Azur by UTMB 50K", shortName: "NCA 50K",
                  distanceKm: 50, elevationGainM: 2800, elevationLossM: 2800, country: "France"),
        KnownRace(name: "Nice Côte d'Azur by UTMB 20K", shortName: "NCA 20K",
                  distanceKm: 20, elevationGainM: 1000, elevationLossM: 1000, country: "France"),

        // MARK: TransLantau by UTMB (Hong Kong)

        KnownRace(name: "TransLantau by UTMB 100K", shortName: "TL100",
                  distanceKm: 100, elevationGainM: 4600, elevationLossM: 4600, country: "Hong Kong"),
        KnownRace(name: "TransLantau by UTMB 50K", shortName: "TL50",
                  distanceKm: 50, elevationGainM: 2300, elevationLossM: 2300, country: "Hong Kong"),
        KnownRace(name: "TransLantau by UTMB 25K", shortName: "TL25",
                  distanceKm: 25, elevationGainM: 1200, elevationLossM: 1200, country: "Hong Kong"),

        // MARK: Thailand by UTMB

        KnownRace(name: "Thailand by UTMB 160K", shortName: nil,
                  distanceKm: 160, elevationGainM: 8500, elevationLossM: 8500, country: "Thailand"),
        KnownRace(name: "Thailand by UTMB 100K", shortName: nil,
                  distanceKm: 100, elevationGainM: 5200, elevationLossM: 5200, country: "Thailand"),
        KnownRace(name: "Thailand by UTMB 50K", shortName: nil,
                  distanceKm: 50, elevationGainM: 2500, elevationLossM: 2500, country: "Thailand"),

        // MARK: Val d'Aran by UTMB (Spain)

        KnownRace(name: "Val d'Aran by UTMB 105K", shortName: nil,
                  distanceKm: 105, elevationGainM: 6500, elevationLossM: 6500, country: "Spain"),
        KnownRace(name: "Val d'Aran by UTMB 55K", shortName: nil,
                  distanceKm: 55, elevationGainM: 3200, elevationLossM: 3200, country: "Spain"),

        // MARK: Kullamannen by UTMB (Sweden)

        KnownRace(name: "Kullamannen by UTMB 100K", shortName: nil,
                  distanceKm: 100, elevationGainM: 2600, elevationLossM: 2600, country: "Sweden"),
        KnownRace(name: "Kullamannen by UTMB 60K", shortName: nil,
                  distanceKm: 60, elevationGainM: 1500, elevationLossM: 1500, country: "Sweden"),

        // MARK: Ultra-Trail Mt. Fuji (Japan)

        KnownRace(name: "Ultra-Trail Mt. Fuji", shortName: "UTMF",
                  distanceKm: 165, elevationGainM: 7942, elevationLossM: 7942, country: "Japan"),
        KnownRace(name: "Ultra-Trail Mt. Fuji 70K", shortName: "UTMF 70K",
                  distanceKm: 70, elevationGainM: 3500, elevationLossM: 3500, country: "Japan"),
        KnownRace(name: "Ultra-Trail Mt. Fuji 45K", shortName: "UTMF 45K",
                  distanceKm: 45, elevationGainM: 2300, elevationLossM: 2300, country: "Japan"),

        // MARK: Canyons Endurance Runs by UTMB (USA)

        KnownRace(name: "Canyons Endurance Runs 200mi", shortName: "Canyons 200",
                  distanceKm: 322, elevationGainM: 18000, elevationLossM: 18000, country: "USA"),
        KnownRace(name: "Canyons Endurance Runs 100K", shortName: "Canyons 100K",
                  distanceKm: 100, elevationGainM: 4900, elevationLossM: 4900, country: "USA"),
        KnownRace(name: "Canyons Endurance Runs 50K", shortName: "Canyons 50K",
                  distanceKm: 50, elevationGainM: 2500, elevationLossM: 2500, country: "USA"),
        KnownRace(name: "Canyons Endurance Runs 25K", shortName: "Canyons 25K",
                  distanceKm: 25, elevationGainM: 1200, elevationLossM: 1200, country: "USA"),

        // MARK: Istria by UTMB (Croatia)

        KnownRace(name: "Istria by UTMB 165K", shortName: nil,
                  distanceKm: 165, elevationGainM: 6500, elevationLossM: 6500, country: "Croatia"),
        KnownRace(name: "Istria by UTMB 100K", shortName: nil,
                  distanceKm: 100, elevationGainM: 4200, elevationLossM: 4200, country: "Croatia"),
        KnownRace(name: "Istria by UTMB 67K", shortName: nil,
                  distanceKm: 67, elevationGainM: 2800, elevationLossM: 2800, country: "Croatia"),

        // MARK: Korea by UTMB (South Korea)

        KnownRace(name: "Korea by UTMB 107K", shortName: nil,
                  distanceKm: 107, elevationGainM: 5900, elevationLossM: 5900, country: "South Korea"),
        KnownRace(name: "Korea by UTMB 56K", shortName: nil,
                  distanceKm: 56, elevationGainM: 3200, elevationLossM: 3200, country: "South Korea"),

        // MARK: Chiangmai by UTMB (Thailand)

        KnownRace(name: "Chiangmai by UTMB 100K", shortName: nil,
                  distanceKm: 100, elevationGainM: 4800, elevationLossM: 4800, country: "Thailand"),
        KnownRace(name: "Chiangmai by UTMB 52K", shortName: nil,
                  distanceKm: 52, elevationGainM: 2500, elevationLossM: 2500, country: "Thailand"),

        // MARK: Indonesia by UTMB

        KnownRace(name: "Indonesia by UTMB 100K", shortName: nil,
                  distanceKm: 100, elevationGainM: 5600, elevationLossM: 5600, country: "Indonesia"),
        KnownRace(name: "Indonesia by UTMB 53K", shortName: nil,
                  distanceKm: 53, elevationGainM: 3000, elevationLossM: 3000, country: "Indonesia"),

        // MARK: Patagonia by UTMB (Argentina)

        KnownRace(name: "Patagonia by UTMB 100K", shortName: nil,
                  distanceKm: 100, elevationGainM: 4000, elevationLossM: 4000, country: "Argentina"),
        KnownRace(name: "Patagonia by UTMB 50K", shortName: nil,
                  distanceKm: 50, elevationGainM: 2000, elevationLossM: 2000, country: "Argentina"),

        // MARK: Malaysia by UTMB

        KnownRace(name: "Malaysia by UTMB 100K", shortName: nil,
                  distanceKm: 100, elevationGainM: 5200, elevationLossM: 5200, country: "Malaysia"),
        KnownRace(name: "Malaysia by UTMB 55K", shortName: nil,
                  distanceKm: 55, elevationGainM: 2800, elevationLossM: 2800, country: "Malaysia"),

        // MARK: Gaoligong by UTMB (China)

        KnownRace(name: "Gaoligong by UTMB 160K", shortName: nil,
                  distanceKm: 160, elevationGainM: 9500, elevationLossM: 9500, country: "China"),
        KnownRace(name: "Gaoligong by UTMB 100K", shortName: nil,
                  distanceKm: 100, elevationGainM: 5800, elevationLossM: 5800, country: "China"),
        KnownRace(name: "Gaoligong by UTMB 55K", shortName: nil,
                  distanceKm: 55, elevationGainM: 3200, elevationLossM: 3200, country: "China"),

        // MARK: Grindstone by UTMB (USA)

        KnownRace(name: "Grindstone by UTMB 100mi", shortName: "Grindstone 100",
                  distanceKm: 161, elevationGainM: 6700, elevationLossM: 6700, country: "USA"),

        // MARK: EcoTrail Paris by UTMB (France)

        KnownRace(name: "EcoTrail Paris by UTMB 80K", shortName: "EcoTrail 80K",
                  distanceKm: 80, elevationGainM: 2000, elevationLossM: 2000, country: "France"),
        KnownRace(name: "EcoTrail Paris by UTMB 45K", shortName: "EcoTrail 45K",
                  distanceKm: 45, elevationGainM: 1100, elevationLossM: 1100, country: "France"),
        KnownRace(name: "EcoTrail Paris by UTMB 30K", shortName: "EcoTrail 30K",
                  distanceKm: 30, elevationGainM: 800, elevationLossM: 800, country: "France"),
        KnownRace(name: "EcoTrail Paris by UTMB 18K", shortName: "EcoTrail 18K",
                  distanceKm: 18, elevationGainM: 400, elevationLossM: 400, country: "France"),

        // MARK: Mozart 100 by UTMB (Austria)

        KnownRace(name: "Mozart 100 by UTMB 100K", shortName: "Mozart 100K",
                  distanceKm: 100, elevationGainM: 5000, elevationLossM: 5000, country: "Austria"),
        KnownRace(name: "Mozart 100 by UTMB 75K", shortName: "Mozart 75K",
                  distanceKm: 75, elevationGainM: 3800, elevationLossM: 3800, country: "Austria"),
        KnownRace(name: "Mozart 100 by UTMB 44K", shortName: "Mozart 44K",
                  distanceKm: 44, elevationGainM: 2200, elevationLossM: 2200, country: "Austria"),
    ]
}
