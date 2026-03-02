import Foundation

struct ClipNutritionPlanData: Codable, Sendable {
    let raceId: UUID
    let raceName: String
    let caloriesPerHour: Int
    let hydrationMlPerHour: Int
    let sodiumMgPerHour: Int
    let hydrationIntervalSeconds: TimeInterval
    let fuelIntervalSeconds: TimeInterval
    let electrolyteIntervalSeconds: TimeInterval
    let entries: [ClipNutritionEntry]
}

struct ClipNutritionEntry: Codable, Sendable, Identifiable {
    let id: UUID
    let productName: String
    let timingMinutes: Int
    let quantity: Int
    let calories: Int
}

enum ClipNutritionDataReader {
    private static let suiteName = "group.com.ultratrain.shared"

    static func readNutritionPlan(raceId: String) -> ClipNutritionPlanData? {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return nil }
        let key = "clip.nutritionPlan.\(raceId)"
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ClipNutritionPlanData.self, from: data)
    }
}
