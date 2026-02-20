import Foundation

enum DefaultChecklistGenerator {

    static func generate(for race: Race) -> [ChecklistItem] {
        var items: [ChecklistItem] = []

        items.append(contentsOf: mandatorySafetyItems())
        items.append(contentsOf: logisticsItems())
        items.append(contentsOf: baseGearItems())
        items.append(contentsOf: baseClothingItems())
        items.append(contentsOf: baseNutritionItems())

        if race.distanceKm > 40 {
            items.append(contentsOf: longRaceItems())
        }

        if race.elevationGainM > 2000 {
            items.append(contentsOf: highElevationItems())
        }

        if race.terrainDifficulty == .technical || race.terrainDifficulty == .extreme {
            items.append(contentsOf: technicalTerrainItems())
        }

        let aidStationCount = race.checkpoints.filter(\.hasAidStation).count
        if aidStationCount > 0 {
            items.append(contentsOf: aidStationItems(count: aidStationCount))
        }

        if race.checkpoints.contains(where: { !$0.hasAidStation }) {
            items.append(contentsOf: dropBagItems())
        }

        return items
    }

    // MARK: - Mandatory Items

    private static func mandatorySafetyItems() -> [ChecklistItem] {
        [
            makeItem("Whistle", category: .safety),
            makeItem("Phone (fully charged)", category: .safety),
            makeItem("Emergency blanket (survival blanket)", category: .safety),
            makeItem("ID / race bib", category: .safety),
            makeItem("First aid kit (blister patches, tape)", category: .safety)
        ]
    }

    private static func logisticsItems() -> [ChecklistItem] {
        [
            makeItem("Bib pickup / registration", category: .logistics),
            makeItem("Transport to start line", category: .logistics),
            makeItem("Transport from finish", category: .logistics),
            makeItem("Accommodation booking", category: .logistics),
            makeItem("Race briefing / course map", category: .logistics)
        ]
    }

    // MARK: - Base Items

    private static func baseGearItems() -> [ChecklistItem] {
        [
            makeItem("Trail shoes", category: .gear),
            makeItem("Running vest / hydration pack", category: .gear),
            makeItem("Water bottles or soft flasks", category: .gear),
            makeItem("GPS watch (charged)", category: .gear)
        ]
    }

    private static func baseClothingItems() -> [ChecklistItem] {
        [
            makeItem("Running shorts / tights", category: .clothing),
            makeItem("Running shirt / top", category: .clothing),
            makeItem("Socks (tested on long runs)", category: .clothing),
            makeItem("Cap or visor", category: .clothing),
            makeItem("Sunglasses", category: .clothing)
        ]
    }

    private static func baseNutritionItems() -> [ChecklistItem] {
        [
            makeItem("Energy gels", category: .nutrition),
            makeItem("Energy bars or chews", category: .nutrition),
            makeItem("Electrolyte tablets / powder", category: .nutrition),
            makeItem("Salt capsules", category: .nutrition)
        ]
    }

    // MARK: - Conditional Items

    private static func longRaceItems() -> [ChecklistItem] {
        [
            makeItem("Headlamp (charged)", category: .gear),
            makeItem("Spare headlamp batteries", category: .gear),
            makeItem("Reflective vest or light", category: .clothing),
            makeItem("Extra warm layer (insulated jacket)", category: .clothing),
            makeItem("Anti-chafe cream", category: .gear)
        ]
    }

    private static func highElevationItems() -> [ChecklistItem] {
        [
            makeItem("Trekking poles", category: .gear),
            makeItem("Waterproof jacket", category: .clothing),
            makeItem("Warm gloves", category: .clothing),
            makeItem("Warm hat / buff", category: .clothing),
            makeItem("Long-sleeve base layer", category: .clothing)
        ]
    }

    private static func technicalTerrainItems() -> [ChecklistItem] {
        [
            makeItem("Ankle-high trail shoes (recommended)", category: .gear,
                     notes: "Technical terrain — consider shoes with good ankle support"),
            makeItem("Protective gloves for scrambling", category: .clothing)
        ]
    }

    private static func aidStationItems(count: Int) -> [ChecklistItem] {
        [
            makeItem("Aid station nutrition plan (what to eat/drink at each)", category: .nutrition,
                     notes: "\(count) aid station(s) on course"),
            makeItem("Personal cup (if required by race)", category: .gear)
        ]
    }

    private static func dropBagItems() -> [ChecklistItem] {
        [
            makeItem("Drop bag packed", category: .dropBag),
            makeItem("Extra food for drop bag", category: .dropBag),
            makeItem("Fresh socks in drop bag", category: .dropBag),
            makeItem("Spare battery / power bank in drop bag", category: .dropBag)
        ]
    }

    // MARK: - Helpers

    private static func makeItem(
        _ name: String,
        category: ChecklistCategory,
        notes: String? = nil
    ) -> ChecklistItem {
        ChecklistItem(
            id: UUID(),
            name: name,
            category: category,
            isChecked: false,
            isCustom: false,
            notes: notes
        )
    }
}
