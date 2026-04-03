import Foundation

// swiftlint:disable:next identifier_name
private func _d(_ year: Int, _ month: Int, _ day: Int) -> Date {
    DateComponents(calendar: .current, year: year, month: month, day: day).date!
}

// MARK: - Europe (excluding France — see RaceDatabase+FranceTrails)

extension RaceDatabase {

    static let europe: [KnownRace] = [

        // MARK: Italy

        KnownRace(name: "Tor des Géants", shortName: "TDG", distanceKm: 330, elevationGainM: 24000,
                  elevationLossM: 24000, country: "Italy", nextEditionDate: _d(2026, 9, 13), terrainDifficulty: .extreme),
        KnownRace(name: "Tor des Glaciers", shortName: nil, distanceKm: 450, elevationGainM: 32000,
                  elevationLossM: 32000, country: "Italy", nextEditionDate: _d(2026, 9, 1), terrainDifficulty: .extreme),
        KnownRace(name: "Gran Trail Courmayeur 100K", shortName: nil, distanceKm: 100, elevationGainM: 6200,
                  elevationLossM: 6200, country: "Italy", nextEditionDate: _d(2026, 7, 11), terrainDifficulty: .technical),
        KnownRace(name: "Dolomyths Run 25K", shortName: nil, distanceKm: 25, elevationGainM: 1700,
                  elevationLossM: 1700, country: "Italy", nextEditionDate: _d(2026, 6, 27), terrainDifficulty: .technical),
        KnownRace(name: "Trofeo Kima", shortName: nil, distanceKm: 52, elevationGainM: 4200,
                  elevationLossM: 4200, country: "Italy", nextEditionDate: _d(2026, 8, 22), terrainDifficulty: .extreme),
        KnownRace(name: "Adamello Ultra Trail 170K", shortName: nil, distanceKm: 170, elevationGainM: 11000,
                  elevationLossM: 11000, country: "Italy", nextEditionDate: _d(2026, 6, 27), terrainDifficulty: .technical),
        KnownRace(name: "Ultra Trail del Lago Maggiore 64K", shortName: nil, distanceKm: 64, elevationGainM: 3800,
                  elevationLossM: 3800, country: "Italy", nextEditionDate: _d(2026, 5, 2), terrainDifficulty: .moderate),
        KnownRace(name: "Etna Trail 80K", shortName: nil, distanceKm: 80, elevationGainM: 4200,
                  elevationLossM: 4200, country: "Italy", nextEditionDate: _d(2026, 6, 6), terrainDifficulty: .moderate),
        KnownRace(name: "Dolomiti Skyrace 22K", shortName: nil, distanceKm: 22, elevationGainM: 1600,
                  elevationLossM: 1600, country: "Italy", nextEditionDate: _d(2026, 7, 25), terrainDifficulty: .technical),
        KnownRace(name: "South Tyrol Ultra Skyrace 121K", shortName: nil, distanceKm: 121, elevationGainM: 7600,
                  elevationLossM: 7600, country: "Italy", nextEditionDate: _d(2026, 6, 20), terrainDifficulty: .technical),

        // MARK: Spain

        KnownRace(name: "Transvulcania", shortName: nil, distanceKm: 74, elevationGainM: 4350,
                  elevationLossM: 4350, country: "Spain", nextEditionDate: _d(2026, 5, 9), terrainDifficulty: .moderate),
        KnownRace(name: "Zegama-Aizkorri Marathon", shortName: "Zegama", distanceKm: 42, elevationGainM: 2736,
                  elevationLossM: 2736, country: "Spain", nextEditionDate: _d(2026, 5, 17), terrainDifficulty: .technical),
        KnownRace(name: "Gran Trail Peñalara 110K", shortName: nil, distanceKm: 110, elevationGainM: 5500,
                  elevationLossM: 5500, country: "Spain", nextEditionDate: _d(2026, 6, 27), terrainDifficulty: .moderate),
        KnownRace(name: "Gran Trail Peñalara 60K", shortName: nil, distanceKm: 60, elevationGainM: 3000,
                  elevationLossM: 3000, country: "Spain", nextEditionDate: _d(2026, 6, 27), terrainDifficulty: .moderate),
        KnownRace(name: "Ultra Sierra Nevada 102K", shortName: nil, distanceKm: 102, elevationGainM: 5500,
                  elevationLossM: 5500, country: "Spain", nextEditionDate: _d(2026, 7, 4), terrainDifficulty: .moderate),
        KnownRace(name: "Cavalls del Vent 83K", shortName: nil, distanceKm: 83, elevationGainM: 5500,
                  elevationLossM: 5500, country: "Spain", nextEditionDate: _d(2026, 9, 19), terrainDifficulty: .technical),
        KnownRace(name: "Canfranc-Canfranc 100K", shortName: nil, distanceKm: 100, elevationGainM: 6500,
                  elevationLossM: 6500, country: "Spain", nextEditionDate: _d(2026, 10, 3), terrainDifficulty: .technical),
        KnownRace(name: "Trail Costa Brava 60K", shortName: nil, distanceKm: 60, elevationGainM: 2800,
                  elevationLossM: 2800, country: "Spain", nextEditionDate: _d(2026, 11, 7), terrainDifficulty: .moderate),
        KnownRace(name: "Olla de Núria 25K Skyrace", shortName: nil, distanceKm: 25, elevationGainM: 1800,
                  elevationLossM: 1800, country: "Spain", nextEditionDate: _d(2026, 7, 18), terrainDifficulty: .technical),

        // MARK: Switzerland

        KnownRace(name: "Eiger Ultra Trail E101", shortName: "E101", distanceKm: 101, elevationGainM: 6700,
                  elevationLossM: 6700, country: "Switzerland", nextEditionDate: _d(2026, 7, 18), terrainDifficulty: .technical),
        KnownRace(name: "Eiger Ultra Trail E51", shortName: "E51", distanceKm: 51, elevationGainM: 3400,
                  elevationLossM: 3400, country: "Switzerland", nextEditionDate: _d(2026, 7, 18), terrainDifficulty: .technical),
        KnownRace(name: "Eiger Ultra Trail E35", shortName: "E35", distanceKm: 35, elevationGainM: 2300,
                  elevationLossM: 2300, country: "Switzerland", nextEditionDate: _d(2026, 7, 18), terrainDifficulty: .technical),
        KnownRace(name: "Swiss Peaks Trail 360K", shortName: nil, distanceKm: 397, elevationGainM: 27530,
                  elevationLossM: 27830, country: "Switzerland", nextEditionDate: _d(2026, 8, 30), terrainDifficulty: .extreme),
        KnownRace(name: "Sierre-Zinal", shortName: nil, distanceKm: 31, elevationGainM: 2200,
                  elevationLossM: 1100, country: "Switzerland", nextEditionDate: _d(2026, 8, 8), terrainDifficulty: .technical),
        KnownRace(name: "Jungfrau Marathon", shortName: nil, distanceKm: 42, elevationGainM: 1829,
                  elevationLossM: 200, country: "Switzerland", nextEditionDate: _d(2026, 9, 12), terrainDifficulty: .moderate),
        KnownRace(name: "Swiss Alpine Marathon Davos 78K", shortName: nil, distanceKm: 78, elevationGainM: 2320,
                  elevationLossM: 2320, country: "Switzerland", nextEditionDate: _d(2026, 7, 25), terrainDifficulty: .moderate),
        KnownRace(name: "Swiss Canyon Trail 111K", shortName: nil, distanceKm: 111, elevationGainM: 6700,
                  elevationLossM: 6700, country: "Switzerland", nextEditionDate: _d(2026, 6, 20), terrainDifficulty: .technical),
        KnownRace(name: "Trail Verbier Saint-Bernard 111K", shortName: "TVSB", distanceKm: 111, elevationGainM: 7100,
                  elevationLossM: 7100, country: "Switzerland", nextEditionDate: _d(2026, 7, 4), terrainDifficulty: .technical),
        KnownRace(name: "Swiss Iron Trail 201K", shortName: nil, distanceKm: 201, elevationGainM: 11200,
                  elevationLossM: 11200, country: "Switzerland", nextEditionDate: _d(2026, 6, 20), terrainDifficulty: .technical),

        // MARK: UK

        KnownRace(name: "Ultra-Trail Snowdonia 100K", shortName: nil, distanceKm: 100, elevationGainM: 5500,
                  elevationLossM: 5500, country: "UK", nextEditionDate: _d(2026, 5, 9), terrainDifficulty: .moderate),
        KnownRace(name: "Lakeland 100", shortName: nil, distanceKm: 161, elevationGainM: 6300,
                  elevationLossM: 6300, country: "UK", nextEditionDate: _d(2026, 7, 24), terrainDifficulty: .moderate),
        KnownRace(name: "Dragon's Back Race", shortName: nil, distanceKm: 380, elevationGainM: 16600,
                  elevationLossM: 16600, country: "UK", nextEditionDate: _d(2026, 9, 7), terrainDifficulty: .technical),
        KnownRace(name: "Montane Spine Race", shortName: "Spine", distanceKm: 431, elevationGainM: 13300,
                  elevationLossM: 13300, country: "UK", nextEditionDate: _d(2026, 1, 11), terrainDifficulty: .moderate),
        KnownRace(name: "NDW 100 (North Downs Way)", shortName: "NDW 100", distanceKm: 161, elevationGainM: 3400,
                  elevationLossM: 3400, country: "UK", nextEditionDate: _d(2026, 8, 8), terrainDifficulty: .easy),
        KnownRace(name: "SDW 100 (South Downs Way)", shortName: "SDW 100", distanceKm: 161, elevationGainM: 4000,
                  elevationLossM: 4000, country: "UK", nextEditionDate: _d(2026, 6, 6), terrainDifficulty: .easy),
        KnownRace(name: "West Highland Way Race", shortName: "WHW", distanceKm: 154, elevationGainM: 4500,
                  elevationLossM: 4500, country: "UK", nextEditionDate: _d(2026, 6, 20), terrainDifficulty: .moderate),
        KnownRace(name: "Glen Coe Skyline 55K", shortName: nil, distanceKm: 55, elevationGainM: 4750,
                  elevationLossM: 4750, country: "UK", nextEditionDate: _d(2026, 9, 19), terrainDifficulty: .extreme),
        KnownRace(name: "Cape Wrath Ultra", shortName: nil, distanceKm: 400, elevationGainM: 11000,
                  elevationLossM: 11000, country: "UK", nextEditionDate: _d(2026, 5, 16), terrainDifficulty: .moderate),
        KnownRace(name: "Highland Fling 53M", shortName: nil, distanceKm: 86, elevationGainM: 2700,
                  elevationLossM: 2700, country: "UK", nextEditionDate: _d(2026, 4, 25), terrainDifficulty: .moderate),
        KnownRace(name: "Ring of Fire 135M", shortName: nil, distanceKm: 217, elevationGainM: 8500,
                  elevationLossM: 8500, country: "UK", nextEditionDate: _d(2026, 8, 28), terrainDifficulty: .moderate),

        // MARK: Scandinavia

        KnownRace(name: "Hamperokken Skyrace 57K", shortName: nil, distanceKm: 57, elevationGainM: 4800,
                  elevationLossM: 4800, country: "Norway", nextEditionDate: _d(2026, 8, 1), terrainDifficulty: .technical),
        KnownRace(name: "Lofoten Ultra-Trail 100K", shortName: nil, distanceKm: 100, elevationGainM: 5100,
                  elevationLossM: 5100, country: "Norway", nextEditionDate: _d(2026, 6, 6), terrainDifficulty: .technical),
        KnownRace(name: "UltraBirken 60K", shortName: nil, distanceKm: 60, elevationGainM: 2100,
                  elevationLossM: 2100, country: "Norway", nextEditionDate: _d(2026, 6, 20), terrainDifficulty: .moderate),
        KnownRace(name: "UltraVasan 90K", shortName: nil, distanceKm: 90, elevationGainM: 750,
                  elevationLossM: 750, country: "Sweden", nextEditionDate: _d(2026, 8, 22), terrainDifficulty: .easy),
        KnownRace(name: "Fjällmaraton 48K", shortName: nil, distanceKm: 48, elevationGainM: 1100,
                  elevationLossM: 1100, country: "Sweden", nextEditionDate: _d(2026, 8, 1), terrainDifficulty: .easy),

        // MARK: Germany & Austria

        KnownRace(name: "Zugspitz Ultratrail 106K", shortName: "ZUT", distanceKm: 106, elevationGainM: 5500,
                  elevationLossM: 5500, country: "Germany", nextEditionDate: _d(2026, 6, 20), terrainDifficulty: .technical),
        KnownRace(name: "Grossglockner Ultra-Trail 110K", shortName: "GGUT", distanceKm: 110, elevationGainM: 6500,
                  elevationLossM: 6500, country: "Austria", nextEditionDate: _d(2026, 7, 25), terrainDifficulty: .technical),
        KnownRace(name: "Innsbruck Alpine Trailrun K85", shortName: nil, distanceKm: 85, elevationGainM: 5300,
                  elevationLossM: 5300, country: "Austria", nextEditionDate: _d(2026, 9, 26), terrainDifficulty: .technical),
        KnownRace(name: "Rennsteig Supermarathon 73K", shortName: nil, distanceKm: 73, elevationGainM: 1600,
                  elevationLossM: 1600, country: "Germany", nextEditionDate: _d(2026, 5, 16), terrainDifficulty: .easy),
        KnownRace(name: "Transalpine Run (8 stages)", shortName: nil, distanceKm: 260, elevationGainM: 15000,
                  elevationLossM: 15000, country: "Austria", nextEditionDate: _d(2026, 9, 5), terrainDifficulty: .technical),

        // MARK: Iceland, Greece, Turkey

        KnownRace(name: "Laugavegur Ultra Marathon 55K", shortName: nil, distanceKm: 55, elevationGainM: 1600,
                  elevationLossM: 1600, country: "Iceland", nextEditionDate: _d(2026, 7, 18), terrainDifficulty: .moderate),
        KnownRace(name: "Olympus Mythical Trail 100K", shortName: nil, distanceKm: 100, elevationGainM: 6500,
                  elevationLossM: 6500, country: "Greece", nextEditionDate: _d(2026, 6, 20), terrainDifficulty: .technical),
        KnownRace(name: "Corfu Mountain Trail 55K", shortName: nil, distanceKm: 55, elevationGainM: 3200,
                  elevationLossM: 3200, country: "Greece", nextEditionDate: _d(2026, 5, 16), terrainDifficulty: .moderate),
        KnownRace(name: "Cappadocia Ultra Trail 110K", shortName: "CUTM", distanceKm: 110, elevationGainM: 3500,
                  elevationLossM: 3500, country: "Turkey", nextEditionDate: _d(2026, 10, 17), terrainDifficulty: .moderate),

        // MARK: Portugal & Andorra

        KnownRace(name: "Grand Trail de Porto 70K", shortName: nil, distanceKm: 70, elevationGainM: 3200,
                  elevationLossM: 3200, country: "Portugal", nextEditionDate: _d(2026, 3, 28), terrainDifficulty: .moderate),
        KnownRace(name: "Ronda dels Cims 170K", shortName: nil, distanceKm: 170, elevationGainM: 13500,
                  elevationLossM: 13500, country: "Andorra", nextEditionDate: _d(2026, 6, 20), terrainDifficulty: .technical),
    ]
}
