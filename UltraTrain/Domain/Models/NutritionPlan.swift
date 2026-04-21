import Foundation

struct NutritionPlan: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    var raceId: UUID
    /// Grams of carbohydrate per hour — the primary modern fuelling target
    /// (Jeukendrup/ISSN). For legacy plans this is derived from `caloriesPerHour`
    /// at 4 kcal/g on decode.
    var carbsPerHour: Int
    var caloriesPerHour: Int
    var hydrationMlPerHour: Int
    var sodiumMgPerHour: Int
    /// Total caffeine mg prescribed across the whole race.
    var totalCaffeineMg: Int
    var entries: [NutritionEntry]
    var gutTrainingSessionIds: [UUID]

    // MARK: - Backwards-compatible Codable

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.raceId = try c.decode(UUID.self, forKey: .raceId)
        self.caloriesPerHour = try c.decode(Int.self, forKey: .caloriesPerHour)
        self.hydrationMlPerHour = try c.decode(Int.self, forKey: .hydrationMlPerHour)
        self.sodiumMgPerHour = try c.decode(Int.self, forKey: .sodiumMgPerHour)
        self.entries = try c.decode([NutritionEntry].self, forKey: .entries)
        self.gutTrainingSessionIds = try c.decode([UUID].self, forKey: .gutTrainingSessionIds)
        // Derived defaults for legacy plans
        self.carbsPerHour = try c.decodeIfPresent(Int.self, forKey: .carbsPerHour) ?? (self.caloriesPerHour / 4)
        self.totalCaffeineMg = try c.decodeIfPresent(Int.self, forKey: .totalCaffeineMg) ?? 0
    }

    init(
        id: UUID,
        raceId: UUID,
        carbsPerHour: Int? = nil,
        caloriesPerHour: Int,
        hydrationMlPerHour: Int,
        sodiumMgPerHour: Int,
        totalCaffeineMg: Int = 0,
        entries: [NutritionEntry],
        gutTrainingSessionIds: [UUID]
    ) {
        self.id = id
        self.raceId = raceId
        self.carbsPerHour = carbsPerHour ?? (caloriesPerHour / 4)
        self.caloriesPerHour = caloriesPerHour
        self.hydrationMlPerHour = hydrationMlPerHour
        self.sodiumMgPerHour = sodiumMgPerHour
        self.totalCaffeineMg = totalCaffeineMg
        self.entries = entries
        self.gutTrainingSessionIds = gutTrainingSessionIds
    }

    private enum CodingKeys: String, CodingKey {
        case id, raceId, carbsPerHour, caloriesPerHour
        case hydrationMlPerHour, sodiumMgPerHour, totalCaffeineMg
        case entries, gutTrainingSessionIds
    }
}
