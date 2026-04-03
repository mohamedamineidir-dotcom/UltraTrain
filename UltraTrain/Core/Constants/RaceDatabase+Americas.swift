import Foundation

// swiftlint:disable:next identifier_name
private func _d(_ year: Int, _ month: Int, _ day: Int) -> Date {
    DateComponents(calendar: .current, year: year, month: month, day: day).date!
}

// MARK: - Americas (USA, Canada, Central & South America)

extension RaceDatabase {

    static let americas: [KnownRace] = [

        // MARK: USA — Iconic 100 Milers

        KnownRace(name: "Hardrock Hundred", shortName: "Hardrock 100", distanceKm: 161, elevationGainM: 10088,
                  elevationLossM: 10088, country: "USA", nextEditionDate: _d(2026, 7, 10), terrainDifficulty: .extreme),
        KnownRace(name: "Leadville Trail 100", shortName: "Leadville 100", distanceKm: 161, elevationGainM: 4800,
                  elevationLossM: 4800, country: "USA", nextEditionDate: _d(2026, 8, 22), terrainDifficulty: .moderate),
        KnownRace(name: "Barkley Marathons", shortName: "Barkley", distanceKm: 210, elevationGainM: 18000,
                  elevationLossM: 18000, country: "USA", nextEditionDate: _d(2026, 3, 28), terrainDifficulty: .extreme),
        KnownRace(name: "Javelina Jundred", shortName: "Javelina 100", distanceKm: 161, elevationGainM: 1800,
                  elevationLossM: 1800, country: "USA", nextEditionDate: _d(2026, 10, 31), terrainDifficulty: .easy),
        KnownRace(name: "HURT 100", shortName: nil, distanceKm: 161, elevationGainM: 7500,
                  elevationLossM: 7500, country: "USA", nextEditionDate: _d(2026, 1, 17), terrainDifficulty: .technical),
        KnownRace(name: "Wasatch 100", shortName: nil, distanceKm: 161, elevationGainM: 7315,
                  elevationLossM: 7102, country: "USA", nextEditionDate: _d(2026, 9, 4), terrainDifficulty: .moderate),
        KnownRace(name: "Bear 100", shortName: nil, distanceKm: 161, elevationGainM: 6700,
                  elevationLossM: 6700, country: "USA", nextEditionDate: _d(2026, 9, 25), terrainDifficulty: .moderate),
        KnownRace(name: "Superior 100", shortName: nil, distanceKm: 161, elevationGainM: 6000,
                  elevationLossM: 6000, country: "USA", nextEditionDate: _d(2026, 9, 11), terrainDifficulty: .moderate),
        KnownRace(name: "Angeles Crest 100", shortName: nil, distanceKm: 161, elevationGainM: 6400,
                  elevationLossM: 6400, country: "USA", nextEditionDate: _d(2026, 8, 1), terrainDifficulty: .moderate),
        KnownRace(name: "Run Rabbit Run 100", shortName: nil, distanceKm: 161, elevationGainM: 6000,
                  elevationLossM: 6000, country: "USA", nextEditionDate: _d(2026, 9, 18), terrainDifficulty: .moderate),
        KnownRace(name: "Pine Creek 100", shortName: nil, distanceKm: 161, elevationGainM: 6900,
                  elevationLossM: 6900, country: "USA", nextEditionDate: _d(2026, 6, 13), terrainDifficulty: .moderate),
        KnownRace(name: "Mogollon Monster 100", shortName: nil, distanceKm: 161, elevationGainM: 8800,
                  elevationLossM: 8800, country: "USA", nextEditionDate: _d(2026, 9, 18), terrainDifficulty: .moderate),
        KnownRace(name: "Cascade Crest 100", shortName: nil, distanceKm: 161, elevationGainM: 7600,
                  elevationLossM: 7600, country: "USA", nextEditionDate: _d(2026, 8, 21), terrainDifficulty: .moderate),
        KnownRace(name: "Burning River 100", shortName: nil, distanceKm: 161, elevationGainM: 2400,
                  elevationLossM: 2400, country: "USA", nextEditionDate: _d(2026, 7, 25), terrainDifficulty: .easy),
        KnownRace(name: "Umstead 100", shortName: nil, distanceKm: 161, elevationGainM: 2700,
                  elevationLossM: 2700, country: "USA", nextEditionDate: _d(2026, 4, 4), terrainDifficulty: .easy),
        KnownRace(name: "Massanutten Mountain Trails 100", shortName: "MMT 100", distanceKm: 161, elevationGainM: 6400,
                  elevationLossM: 6400, country: "USA", nextEditionDate: _d(2026, 5, 16), terrainDifficulty: .moderate),
        KnownRace(name: "Vermont 100", shortName: nil, distanceKm: 161, elevationGainM: 4700,
                  elevationLossM: 4700, country: "USA", nextEditionDate: _d(2026, 7, 18), terrainDifficulty: .moderate),
        KnownRace(name: "Bighorn Trail 100", shortName: nil, distanceKm: 161, elevationGainM: 5200,
                  elevationLossM: 5200, country: "USA", nextEditionDate: _d(2026, 6, 20), terrainDifficulty: .moderate),
        KnownRace(name: "Kettle Moraine 100", shortName: nil, distanceKm: 161, elevationGainM: 2800,
                  elevationLossM: 2800, country: "USA", nextEditionDate: _d(2026, 6, 6), terrainDifficulty: .easy),
        KnownRace(name: "San Diego 100", shortName: nil, distanceKm: 161, elevationGainM: 6200,
                  elevationLossM: 6200, country: "USA", nextEditionDate: _d(2026, 6, 6), terrainDifficulty: .moderate),

        // MARK: USA — 200+ Milers

        KnownRace(name: "Moab 240", shortName: nil, distanceKm: 389, elevationGainM: 9620,
                  elevationLossM: 9620, country: "USA", nextEditionDate: _d(2026, 10, 9), terrainDifficulty: .moderate),
        KnownRace(name: "Tahoe 200", shortName: nil, distanceKm: 322, elevationGainM: 11234,
                  elevationLossM: 11234, country: "USA", nextEditionDate: _d(2026, 6, 12), terrainDifficulty: .moderate),
        KnownRace(name: "Cocodona 250", shortName: nil, distanceKm: 407, elevationGainM: 11823,
                  elevationLossM: 10328, country: "USA", nextEditionDate: _d(2026, 5, 4), terrainDifficulty: .moderate),
        KnownRace(name: "Bigfoot 200", shortName: nil, distanceKm: 330, elevationGainM: 14000,
                  elevationLossM: 14000, country: "USA", nextEditionDate: _d(2026, 8, 7), terrainDifficulty: .moderate),

        // MARK: USA — Desert & Extreme

        KnownRace(name: "Badwater 135", shortName: nil, distanceKm: 217, elevationGainM: 4450,
                  elevationLossM: 1859, country: "USA", nextEditionDate: _d(2026, 7, 27), terrainDifficulty: .moderate),

        // MARK: USA — 50+ Milers

        KnownRace(name: "JFK 50 Mile", shortName: nil, distanceKm: 80, elevationGainM: 2100,
                  elevationLossM: 2100, country: "USA", nextEditionDate: _d(2026, 11, 21), terrainDifficulty: .easy),
        KnownRace(name: "Rim to Rim to Rim Grand Canyon", shortName: "R2R2R", distanceKm: 68, elevationGainM: 3200,
                  elevationLossM: 3200, country: "USA", terrainDifficulty: .moderate),
        KnownRace(name: "Pikes Peak Marathon", shortName: nil, distanceKm: 42, elevationGainM: 2382,
                  elevationLossM: 2382, country: "USA", nextEditionDate: _d(2026, 9, 19), terrainDifficulty: .moderate),
        KnownRace(name: "Black Canyon 100K", shortName: nil, distanceKm: 100, elevationGainM: 1610,
                  elevationLossM: 2260, country: "USA", nextEditionDate: _d(2026, 2, 14), terrainDifficulty: .moderate),
        KnownRace(name: "Bandera 100K", shortName: nil, distanceKm: 100, elevationGainM: 3300,
                  elevationLossM: 3300, country: "USA", nextEditionDate: _d(2026, 1, 10), terrainDifficulty: .moderate),
        KnownRace(name: "Sean O'Brien 100K", shortName: nil, distanceKm: 100, elevationGainM: 4600,
                  elevationLossM: 4600, country: "USA", nextEditionDate: _d(2026, 2, 7), terrainDifficulty: .moderate),
        KnownRace(name: "Miwok 100K", shortName: nil, distanceKm: 100, elevationGainM: 4500,
                  elevationLossM: 4500, country: "USA", nextEditionDate: _d(2026, 5, 2), terrainDifficulty: .moderate),
        KnownRace(name: "Georgia Death Race 68M", shortName: nil, distanceKm: 109, elevationGainM: 5100,
                  elevationLossM: 5100, country: "USA", nextEditionDate: _d(2026, 3, 14), terrainDifficulty: .moderate),
        KnownRace(name: "Chuckanut 50K", shortName: nil, distanceKm: 50, elevationGainM: 2000,
                  elevationLossM: 2000, country: "USA", nextEditionDate: _d(2026, 3, 21), terrainDifficulty: .moderate),
        KnownRace(name: "Lake Sonoma 50M", shortName: nil, distanceKm: 80, elevationGainM: 3000,
                  elevationLossM: 3000, country: "USA", nextEditionDate: _d(2026, 4, 11), terrainDifficulty: .moderate),
        KnownRace(name: "Gorge Waterfalls 100K", shortName: nil, distanceKm: 100, elevationGainM: 4600,
                  elevationLossM: 4600, country: "USA", nextEditionDate: _d(2026, 4, 4), terrainDifficulty: .moderate),
        KnownRace(name: "Broken Arrow Skyrace 52K", shortName: nil, distanceKm: 52, elevationGainM: 3200,
                  elevationLossM: 3200, country: "USA", nextEditionDate: _d(2026, 6, 20), terrainDifficulty: .technical),
        KnownRace(name: "Speedgoat 50K", shortName: nil, distanceKm: 50, elevationGainM: 3400,
                  elevationLossM: 3400, country: "USA", nextEditionDate: _d(2026, 7, 25), terrainDifficulty: .technical),

        // MARK: Canada

        KnownRace(name: "Ultra-Trail Harricana 125K", shortName: "UTHC", distanceKm: 125, elevationGainM: 3500,
                  elevationLossM: 3500, country: "Canada", nextEditionDate: _d(2026, 9, 12), terrainDifficulty: .moderate),
        KnownRace(name: "Ultra-Trail Harricana 65K", shortName: nil, distanceKm: 65, elevationGainM: 1800,
                  elevationLossM: 1800, country: "Canada", nextEditionDate: _d(2026, 9, 12), terrainDifficulty: .moderate),
        KnownRace(name: "Sinister 7 Ultra 161K", shortName: nil, distanceKm: 161, elevationGainM: 6900,
                  elevationLossM: 6900, country: "Canada", nextEditionDate: _d(2026, 7, 11), terrainDifficulty: .moderate),
        KnownRace(name: "Fat Dog 120", shortName: nil, distanceKm: 193, elevationGainM: 8700,
                  elevationLossM: 8700, country: "Canada", nextEditionDate: _d(2026, 8, 8), terrainDifficulty: .moderate),
        KnownRace(name: "Canadian Death Race 125K", shortName: nil, distanceKm: 125, elevationGainM: 5200,
                  elevationLossM: 5200, country: "Canada", nextEditionDate: _d(2026, 8, 1), terrainDifficulty: .moderate),

        // MARK: Mexico & Central America

        KnownRace(name: "Ultra Trail Cerro Rojo 100K", shortName: nil, distanceKm: 100, elevationGainM: 5000,
                  elevationLossM: 5000, country: "Mexico", nextEditionDate: _d(2026, 3, 7), terrainDifficulty: .moderate),
        KnownRace(name: "Caballo Blanco Ultra 80K", shortName: nil, distanceKm: 80, elevationGainM: 3500,
                  elevationLossM: 3500, country: "Mexico", nextEditionDate: _d(2026, 3, 1), terrainDifficulty: .moderate),

        // MARK: South America

        KnownRace(name: "Ultra-Trail Torres del Paine 80K", shortName: "UTTP", distanceKm: 80, elevationGainM: 4300,
                  elevationLossM: 4300, country: "Chile", nextEditionDate: _d(2026, 9, 26), terrainDifficulty: .moderate),
        KnownRace(name: "Patagonia Run 100K", shortName: nil, distanceKm: 100, elevationGainM: 4000,
                  elevationLossM: 4000, country: "Argentina", nextEditionDate: _d(2026, 4, 11), terrainDifficulty: .moderate),
        KnownRace(name: "Ultra Fiord 100K", shortName: nil, distanceKm: 100, elevationGainM: 4000,
                  elevationLossM: 4000, country: "Chile", nextEditionDate: _d(2026, 5, 2), terrainDifficulty: .moderate),
        KnownRace(name: "Atacama Crossing", shortName: nil, distanceKm: 250, elevationGainM: 3000,
                  elevationLossM: 3000, country: "Chile", nextEditionDate: _d(2026, 10, 4), terrainDifficulty: .easy),
        KnownRace(name: "Ultra Trail Machu Picchu 100K", shortName: nil, distanceKm: 100, elevationGainM: 5000,
                  elevationLossM: 5000, country: "Peru", nextEditionDate: _d(2026, 7, 4), terrainDifficulty: .technical),
        KnownRace(name: "The North Face Endurance Challenge Argentina 80K", shortName: nil, distanceKm: 80,
                  elevationGainM: 3000, elevationLossM: 3000, country: "Argentina", nextEditionDate: _d(2026, 4, 25),
                  terrainDifficulty: .moderate),
        KnownRace(name: "Ultra Trail Cusco 100K", shortName: nil, distanceKm: 100, elevationGainM: 5500,
                  elevationLossM: 5500, country: "Peru", nextEditionDate: _d(2026, 8, 15), terrainDifficulty: .technical),
    ]
}
