import Foundation
import Testing
@testable import UltraTrain

@Suite("DefaultChecklistGenerator Tests")
struct DefaultChecklistGeneratorTests {

    // MARK: - Helpers

    private func makeRace(
        distanceKm: Double = 50,
        elevationGainM: Double = 2500,
        elevationLossM: Double = 2500,
        terrainDifficulty: TerrainDifficulty = .moderate,
        checkpoints: [Checkpoint] = []
    ) -> Race {
        Race(
            id: UUID(),
            name: "Test Race",
            date: Date.now.adding(days: 30),
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: elevationLossM,
            priority: .aRace,
            goalType: .finish,
            checkpoints: checkpoints,
            terrainDifficulty: terrainDifficulty
        )
    }

    private func makeCheckpoint(
        name: String = "CP",
        distanceKm: Double = 25,
        hasAidStation: Bool = true
    ) -> Checkpoint {
        Checkpoint(
            id: UUID(),
            name: name,
            distanceFromStartKm: distanceKm,
            elevationM: 1000,
            hasAidStation: hasAidStation
        )
    }

    // MARK: - Mandatory Safety Items

    @Test("All races include mandatory safety items")
    func mandatorySafetyItems() {
        let race = makeRace(distanceKm: 20, elevationGainM: 500)
        let items = DefaultChecklistGenerator.generate(for: race)

        let safetyItems = items.filter { $0.category == .safety }
        #expect(safetyItems.count >= 4)
        #expect(safetyItems.contains { $0.name.lowercased().contains("whistle") })
        #expect(safetyItems.contains { $0.name.lowercased().contains("phone") })
        #expect(safetyItems.contains { $0.name.lowercased().contains("emergency blanket") })
    }

    // MARK: - Logistics Items

    @Test("All races include logistics items")
    func logisticsItems() {
        let race = makeRace(distanceKm: 20, elevationGainM: 300)
        let items = DefaultChecklistGenerator.generate(for: race)

        let logistics = items.filter { $0.category == .logistics }
        #expect(logistics.count >= 3)
        #expect(logistics.contains { $0.name.lowercased().contains("bib") })
        #expect(logistics.contains { $0.name.lowercased().contains("transport") })
    }

    // MARK: - Short Race

    @Test("Short race does not include headlamp or drop bag")
    func shortRace() {
        let race = makeRace(distanceKm: 25, elevationGainM: 800)
        let items = DefaultChecklistGenerator.generate(for: race)

        let headlampItems = items.filter { $0.name.lowercased().contains("headlamp") }
        #expect(headlampItems.isEmpty)

        let dropBagItems = items.filter { $0.category == .dropBag }
        #expect(dropBagItems.isEmpty)
    }

    // MARK: - Long Race

    @Test("Long race includes headlamp and extra layers")
    func longRace() {
        let race = makeRace(distanceKm: 80, elevationGainM: 1500)
        let items = DefaultChecklistGenerator.generate(for: race)

        #expect(items.contains { $0.name.lowercased().contains("headlamp") })
        #expect(items.contains { $0.name.lowercased().contains("warm layer") || $0.name.lowercased().contains("insulated") })
    }

    // MARK: - High Elevation

    @Test("High elevation race includes poles and warm clothing")
    func highElevation() {
        let race = makeRace(distanceKm: 50, elevationGainM: 3000)
        let items = DefaultChecklistGenerator.generate(for: race)

        #expect(items.contains { $0.name.lowercased().contains("poles") })
        #expect(items.contains { $0.name.lowercased().contains("waterproof jacket") })
        #expect(items.contains { $0.name.lowercased().contains("gloves") })
    }

    @Test("Low elevation race does not include poles")
    func lowElevation() {
        let race = makeRace(distanceKm: 30, elevationGainM: 500)
        let items = DefaultChecklistGenerator.generate(for: race)

        let poleItems = items.filter { $0.name.lowercased().contains("poles") }
        #expect(poleItems.isEmpty)
    }

    // MARK: - Technical Terrain

    @Test("Technical terrain includes ankle support note")
    func technicalTerrain() {
        let race = makeRace(terrainDifficulty: .technical)
        let items = DefaultChecklistGenerator.generate(for: race)

        #expect(items.contains { $0.name.lowercased().contains("ankle") })
    }

    @Test("Easy terrain does not include ankle support note")
    func easyTerrain() {
        let race = makeRace(distanceKm: 30, elevationGainM: 500, terrainDifficulty: .easy)
        let items = DefaultChecklistGenerator.generate(for: race)

        let ankleItems = items.filter { $0.name.lowercased().contains("ankle") }
        #expect(ankleItems.isEmpty)
    }

    // MARK: - Aid Stations

    @Test("Aid stations generate nutrition plan items")
    func aidStationItems() {
        let checkpoints = [
            makeCheckpoint(name: "CP1", distanceKm: 15, hasAidStation: true),
            makeCheckpoint(name: "CP2", distanceKm: 30, hasAidStation: true)
        ]
        let race = makeRace(checkpoints: checkpoints)
        let items = DefaultChecklistGenerator.generate(for: race)

        let nutritionPlanItems = items.filter {
            $0.category == .nutrition && $0.name.lowercased().contains("aid station")
        }
        #expect(!nutritionPlanItems.isEmpty)
        #expect(nutritionPlanItems.first?.notes?.contains("2") == true)
    }

    // MARK: - Drop Bag

    @Test("Non-aid-station checkpoint triggers drop bag items")
    func dropBagItems() {
        let checkpoints = [
            makeCheckpoint(name: "CP1", hasAidStation: true),
            makeCheckpoint(name: "CP2", hasAidStation: false)
        ]
        let race = makeRace(checkpoints: checkpoints)
        let items = DefaultChecklistGenerator.generate(for: race)

        let dropBag = items.filter { $0.category == .dropBag }
        #expect(!dropBag.isEmpty)
    }

    // MARK: - No Custom Items Generated

    @Test("All generated items have isCustom set to false")
    func noCustomItems() {
        let race = makeRace()
        let items = DefaultChecklistGenerator.generate(for: race)

        #expect(items.allSatisfy { !$0.isCustom })
    }

    // MARK: - All Items Unchecked

    @Test("All generated items start unchecked")
    func allUnchecked() {
        let race = makeRace()
        let items = DefaultChecklistGenerator.generate(for: race)

        #expect(items.allSatisfy { !$0.isChecked })
    }

    // MARK: - Base Items Present

    @Test("All races include gear and clothing basics")
    func baseItems() {
        let race = makeRace(distanceKm: 20, elevationGainM: 300)
        let items = DefaultChecklistGenerator.generate(for: race)

        #expect(items.contains { $0.category == .gear && $0.name.lowercased().contains("shoes") })
        #expect(items.contains { $0.category == .gear && $0.name.lowercased().contains("watch") })
        #expect(items.contains { $0.category == .clothing && $0.name.lowercased().contains("socks") })
        #expect(items.contains { $0.category == .nutrition && $0.name.lowercased().contains("gels") })
    }
}
