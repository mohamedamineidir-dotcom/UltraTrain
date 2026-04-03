import Foundation

// swiftlint:disable:next identifier_name
private func _d(_ year: Int, _ month: Int, _ day: Int) -> Date {
    DateComponents(calendar: .current, year: year, month: month, day: day).date!
}

// MARK: - France Trail Races

extension RaceDatabase {

    static let franceTrails: [KnownRace] = [

        // MARK: Réunion — Grand Raid

        KnownRace(name: "Diagonale des Fous", shortName: "Grand Raid", distanceKm: 180, elevationGainM: 10200,
                  elevationLossM: 10200, country: "France", nextEditionDate: _d(2026, 10, 15), terrainDifficulty: .extreme),
        KnownRace(name: "Trail de Bourbon", shortName: nil, distanceKm: 105, elevationGainM: 6200,
                  elevationLossM: 6200, country: "France", nextEditionDate: _d(2026, 10, 16), terrainDifficulty: .technical),
        KnownRace(name: "Mascareignes", shortName: nil, distanceKm: 73, elevationGainM: 3800,
                  elevationLossM: 3800, country: "France", nextEditionDate: _d(2026, 10, 16), terrainDifficulty: .moderate),

        // MARK: Marathon du Mont-Blanc

        KnownRace(name: "90km du Mont-Blanc", shortName: "90K MdMB", distanceKm: 92, elevationGainM: 6330,
                  elevationLossM: 6330, country: "France", nextEditionDate: _d(2026, 6, 26), terrainDifficulty: .technical),
        KnownRace(name: "Marathon du Mont-Blanc 42K", shortName: "MMB 42K", distanceKm: 42, elevationGainM: 2540,
                  elevationLossM: 2540, country: "France", nextEditionDate: _d(2026, 6, 28), terrainDifficulty: .technical),
        KnownRace(name: "23K du Mont-Blanc", shortName: "23K MdMB", distanceKm: 23, elevationGainM: 1680,
                  elevationLossM: 870, country: "France", nextEditionDate: _d(2026, 6, 27), terrainDifficulty: .moderate),
        KnownRace(name: "Kilomètre Vertical du Mont-Blanc", shortName: "KV MdMB", distanceKm: 3.8, elevationGainM: 1000,
                  elevationLossM: 0, country: "France", nextEditionDate: _d(2026, 6, 25), terrainDifficulty: .technical),
        KnownRace(name: "10K du Mont-Blanc", shortName: "10K MdMB", distanceKm: 10, elevationGainM: 500,
                  elevationLossM: 500, country: "France", nextEditionDate: _d(2026, 6, 25), terrainDifficulty: .easy),

        // MARK: Iconic French Trails

        KnownRace(name: "Échappée Belle", shortName: nil, distanceKm: 152, elevationGainM: 11390,
                  elevationLossM: 11390, country: "France", nextEditionDate: _d(2026, 8, 21), terrainDifficulty: .technical),
        KnownRace(name: "Ultra-Trail du Vercors", shortName: "UTV", distanceKm: 84, elevationGainM: 4200,
                  elevationLossM: 4200, country: "France", nextEditionDate: _d(2026, 9, 12), terrainDifficulty: .moderate),
        KnownRace(name: "SaintéLyon", shortName: nil, distanceKm: 80, elevationGainM: 1950,
                  elevationLossM: 2265, country: "France", nextEditionDate: _d(2026, 11, 29), terrainDifficulty: .easy),
        KnownRace(name: "Ultra-Trail Côte d'Azur Mercantour 120K", shortName: "UTCAM", distanceKm: 120, elevationGainM: 7800,
                  elevationLossM: 7800, country: "France", nextEditionDate: _d(2026, 7, 4), terrainDifficulty: .technical),
        KnownRace(name: "Ultra-Trail Côte d'Azur SkyUltra 75K", shortName: nil, distanceKm: 75, elevationGainM: 5100,
                  elevationLossM: 5100, country: "France", nextEditionDate: _d(2026, 7, 4), terrainDifficulty: .moderate),
        KnownRace(name: "Maxi-Race Tour du Lac 94K", shortName: nil, distanceKm: 94, elevationGainM: 5300,
                  elevationLossM: 5300, country: "France", nextEditionDate: _d(2026, 5, 30), terrainDifficulty: .moderate),
        KnownRace(name: "Maxi-Race Marathon 42K", shortName: nil, distanceKm: 42, elevationGainM: 2500,
                  elevationLossM: 2500, country: "France", nextEditionDate: _d(2026, 5, 30), terrainDifficulty: .moderate),

        // MARK: Trail des Templiers (Festival des Templiers, Millau)

        KnownRace(name: "Trail des Templiers", shortName: nil, distanceKm: 80, elevationGainM: 3530,
                  elevationLossM: 3530, country: "France", nextEditionDate: _d(2026, 10, 18), terrainDifficulty: .moderate),
        KnownRace(name: "Endurance Trail des Templiers", shortName: nil, distanceKm: 100, elevationGainM: 4300,
                  elevationLossM: 4300, country: "France", nextEditionDate: _d(2026, 10, 16), terrainDifficulty: .moderate),

        // MARK: Grand Raid des Pyrénées

        KnownRace(name: "Grand Raid des Pyrénées Ultra Tour 160K", shortName: "GRP Ultra", distanceKm: 160, elevationGainM: 10000,
                  elevationLossM: 10000, country: "France", nextEditionDate: _d(2026, 8, 21), terrainDifficulty: .technical),
        KnownRace(name: "Grand Raid des Pyrénées Tour des Cirques 120K", shortName: "GRP 120K", distanceKm: 120, elevationGainM: 7500,
                  elevationLossM: 7500, country: "France", nextEditionDate: _d(2026, 8, 22), terrainDifficulty: .technical),
        KnownRace(name: "Grand Raid des Pyrénées Tour des Lacs 80K", shortName: "GRP 80K", distanceKm: 80, elevationGainM: 5000,
                  elevationLossM: 5000, country: "France", nextEditionDate: _d(2026, 8, 22), terrainDifficulty: .moderate),
        KnownRace(name: "Grand Raid des Pyrénées 40K", shortName: "GRP 40K", distanceKm: 40, elevationGainM: 2500,
                  elevationLossM: 2500, country: "France", nextEditionDate: _d(2026, 8, 22), terrainDifficulty: .moderate),

        // MARK: Ut4M (Ultra Tour des 4 Massifs, Grenoble)

        KnownRace(name: "Ut4M 180 Xtrem", shortName: nil, distanceKm: 177, elevationGainM: 11700,
                  elevationLossM: 11700, country: "France", nextEditionDate: _d(2026, 7, 17), terrainDifficulty: .technical),
        KnownRace(name: "Ut4M 100 Master", shortName: nil, distanceKm: 97, elevationGainM: 5900,
                  elevationLossM: 5900, country: "France", nextEditionDate: _d(2026, 7, 18), terrainDifficulty: .moderate),
        KnownRace(name: "Ut4M 40K", shortName: nil, distanceKm: 40, elevationGainM: 2500,
                  elevationLossM: 2500, country: "France", nextEditionDate: _d(2026, 7, 18), terrainDifficulty: .moderate),

        // MARK: Ultra Marin (Golfe du Morbihan)

        KnownRace(name: "Ultra Marin 175K", shortName: nil, distanceKm: 175, elevationGainM: 1450,
                  elevationLossM: 1450, country: "France", nextEditionDate: _d(2026, 6, 26), terrainDifficulty: .easy),
        KnownRace(name: "Ultra Marin L'Arvor 56K", shortName: nil, distanceKm: 56, elevationGainM: 500,
                  elevationLossM: 500, country: "France", nextEditionDate: _d(2026, 6, 27), terrainDifficulty: .easy),

        // MARK: Grand Trail des Écrins

        KnownRace(name: "Trans'Écrins 59K", shortName: "GTE", distanceKm: 59, elevationGainM: 3400,
                  elevationLossM: 3400, country: "France", nextEditionDate: _d(2026, 6, 20), terrainDifficulty: .moderate),
        KnownRace(name: "Trail des Écrins 34K", shortName: nil, distanceKm: 34, elevationGainM: 2000,
                  elevationLossM: 2000, country: "France", nextEditionDate: _d(2026, 6, 20), terrainDifficulty: .moderate),

        // MARK: More French Ultras & Trails

        KnownRace(name: "6000D - La Course des Géants", shortName: "6000D", distanceKm: 68, elevationGainM: 3800,
                  elevationLossM: 3800, country: "France", nextEditionDate: _d(2026, 7, 4), terrainDifficulty: .moderate),
        KnownRace(name: "Infernal Trail des Vosges 200K", shortName: "IT 200", distanceKm: 205, elevationGainM: 10500,
                  elevationLossM: 10500, country: "France", nextEditionDate: _d(2026, 9, 10), terrainDifficulty: .moderate),
        KnownRace(name: "Trophée des Vosges", shortName: nil, distanceKm: 57, elevationGainM: 2800,
                  elevationLossM: 2800, country: "France", nextEditionDate: _d(2026, 9, 5), terrainDifficulty: .moderate),
        KnownRace(name: "MiL'K 100 Miles", shortName: nil, distanceKm: 160, elevationGainM: 9000,
                  elevationLossM: 9000, country: "France", nextEditionDate: _d(2026, 10, 3), terrainDifficulty: .moderate),
        KnownRace(name: "100 Miles Sud de France", shortName: nil, distanceKm: 160, elevationGainM: 7000,
                  elevationLossM: 7000, country: "France", nextEditionDate: _d(2026, 6, 20), terrainDifficulty: .moderate),
        KnownRace(name: "La Montagn'Hard 100K", shortName: nil, distanceKm: 100, elevationGainM: 5500,
                  elevationLossM: 5500, country: "France", nextEditionDate: _d(2026, 8, 15), terrainDifficulty: .moderate),
        KnownRace(name: "Trail de Faverges", shortName: nil, distanceKm: 76, elevationGainM: 4500,
                  elevationLossM: 4500, country: "France", nextEditionDate: _d(2026, 6, 6), terrainDifficulty: .moderate),
        KnownRace(name: "Trail des Aiguilles Rouges", shortName: nil, distanceKm: 56, elevationGainM: 3600,
                  elevationLossM: 3600, country: "France", nextEditionDate: _d(2026, 7, 11), terrainDifficulty: .technical),
        KnownRace(name: "Aravis Trail 70K", shortName: nil, distanceKm: 70, elevationGainM: 4500,
                  elevationLossM: 4500, country: "France", nextEditionDate: _d(2026, 7, 4), terrainDifficulty: .technical),
        KnownRace(name: "Serre Chevalier Trail 60K", shortName: nil, distanceKm: 60, elevationGainM: 3800,
                  elevationLossM: 3800, country: "France", nextEditionDate: _d(2026, 7, 25), terrainDifficulty: .moderate),
        KnownRace(name: "Trail du Sancy 42K", shortName: nil, distanceKm: 42, elevationGainM: 2500,
                  elevationLossM: 2500, country: "France", nextEditionDate: _d(2026, 6, 20), terrainDifficulty: .moderate),
        KnownRace(name: "Beaujolais Trail 70K", shortName: nil, distanceKm: 70, elevationGainM: 3000,
                  elevationLossM: 3000, country: "France", nextEditionDate: _d(2026, 11, 7), terrainDifficulty: .moderate),
        KnownRace(name: "Trail du Ventoux 46K", shortName: nil, distanceKm: 46, elevationGainM: 2200,
                  elevationLossM: 2200, country: "France", nextEditionDate: _d(2026, 6, 13), terrainDifficulty: .moderate),
        KnownRace(name: "Ergysport Trail du Ventoux 75K", shortName: nil, distanceKm: 75, elevationGainM: 4000,
                  elevationLossM: 4000, country: "France", nextEditionDate: _d(2026, 3, 28), terrainDifficulty: .moderate),
        KnownRace(name: "Trail du Queyras 60K", shortName: nil, distanceKm: 60, elevationGainM: 4000,
                  elevationLossM: 4000, country: "France", nextEditionDate: _d(2026, 7, 11), terrainDifficulty: .technical),
        KnownRace(name: "Trail de la Sainte Victoire 40K", shortName: nil, distanceKm: 40, elevationGainM: 2000,
                  elevationLossM: 2000, country: "France", nextEditionDate: _d(2026, 4, 4), terrainDifficulty: .moderate),
        KnownRace(name: "Chartreuse Trail Festival 60K", shortName: nil, distanceKm: 60, elevationGainM: 3800,
                  elevationLossM: 3800, country: "France", nextEditionDate: _d(2026, 6, 13), terrainDifficulty: .moderate),
        KnownRace(name: "Trail des Passerelles du Monteynard 26K", shortName: nil, distanceKm: 26, elevationGainM: 1500,
                  elevationLossM: 1500, country: "France", nextEditionDate: _d(2026, 6, 6), terrainDifficulty: .moderate),
        KnownRace(name: "Endurance Trail 92K", shortName: nil, distanceKm: 92, elevationGainM: 3500,
                  elevationLossM: 3500, country: "France", nextEditionDate: _d(2026, 3, 14), terrainDifficulty: .easy),

        // MARK: Corsica

        KnownRace(name: "Restonica Trail 68K", shortName: nil, distanceKm: 68, elevationGainM: 4000,
                  elevationLossM: 4000, country: "France", nextEditionDate: _d(2026, 7, 11), terrainDifficulty: .technical),
        KnownRace(name: "Ultra Trail di Corsica 100K", shortName: nil, distanceKm: 100, elevationGainM: 6000,
                  elevationLossM: 6000, country: "France", nextEditionDate: _d(2026, 7, 4), terrainDifficulty: .technical),

        // MARK: Pyrénées & Southwest

        KnownRace(name: "Trail du Pays Basque 42K", shortName: nil, distanceKm: 42, elevationGainM: 2400,
                  elevationLossM: 2400, country: "France", nextEditionDate: _d(2026, 9, 19), terrainDifficulty: .moderate),
        KnownRace(name: "Euskal Trail 80K", shortName: nil, distanceKm: 80, elevationGainM: 4500,
                  elevationLossM: 4500, country: "France", nextEditionDate: _d(2026, 10, 3), terrainDifficulty: .moderate),
        KnownRace(name: "Grand Trail des Cathares 100K", shortName: nil, distanceKm: 100, elevationGainM: 5000,
                  elevationLossM: 5000, country: "France", nextEditionDate: _d(2026, 6, 27), terrainDifficulty: .moderate),
        KnownRace(name: "Trail de Font Romeu 50K", shortName: nil, distanceKm: 50, elevationGainM: 2800,
                  elevationLossM: 2800, country: "France", nextEditionDate: _d(2026, 7, 11), terrainDifficulty: .moderate),
        KnownRace(name: "Grand Raid du Morbihan 95K", shortName: nil, distanceKm: 95, elevationGainM: 2500,
                  elevationLossM: 2500, country: "France", nextEditionDate: _d(2026, 11, 14), terrainDifficulty: .easy),

        // MARK: Urban & Accessible Trails

        KnownRace(name: "Lyon Urban Trail 23K", shortName: nil, distanceKm: 23, elevationGainM: 600,
                  elevationLossM: 600, country: "France", nextEditionDate: _d(2026, 4, 19), terrainDifficulty: .easy),
        KnownRace(name: "Trail de la Côte d'Opale 57K", shortName: nil, distanceKm: 57, elevationGainM: 1400,
                  elevationLossM: 1400, country: "France", nextEditionDate: _d(2026, 10, 17), terrainDifficulty: .easy),
        KnownRace(name: "Marseille Trail des Calanques 26K", shortName: nil, distanceKm: 26, elevationGainM: 1200,
                  elevationLossM: 1200, country: "France", nextEditionDate: _d(2026, 3, 21), terrainDifficulty: .moderate),
        KnownRace(name: "Trail de Bordeaux 30K", shortName: nil, distanceKm: 30, elevationGainM: 800,
                  elevationLossM: 800, country: "France", nextEditionDate: _d(2026, 3, 28), terrainDifficulty: .easy),
        KnownRace(name: "Trail du Grand Raid 73 Savoie", shortName: nil, distanceKm: 73, elevationGainM: 4200,
                  elevationLossM: 4200, country: "France", nextEditionDate: _d(2026, 8, 29), terrainDifficulty: .moderate),
    ]
}
