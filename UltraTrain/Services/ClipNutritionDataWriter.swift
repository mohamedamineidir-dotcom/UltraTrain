import Foundation
import os

enum ClipNutritionDataWriter {
    private static let suiteName = "group.com.ultratrain.shared"

    static func writeNutritionPlan(
        raceId: UUID,
        raceName: String,
        caloriesPerHour: Int,
        hydrationMlPerHour: Int,
        sodiumMgPerHour: Int,
        hydrationIntervalSeconds: TimeInterval,
        fuelIntervalSeconds: TimeInterval,
        electrolyteIntervalSeconds: TimeInterval,
        entries: [(id: UUID, productName: String, timingMinutes: Int, quantity: Int, calories: Int)]
    ) {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Logger.persistence.error("Failed to access shared app group for clip data")
            return
        }

        let entryData = entries.map { entry in
            ClipNutritionEntryDTO(
                id: entry.id,
                productName: entry.productName,
                timingMinutes: entry.timingMinutes,
                quantity: entry.quantity,
                calories: entry.calories
            )
        }

        let clipData = ClipNutritionPlanDTO(
            raceId: raceId,
            raceName: raceName,
            caloriesPerHour: caloriesPerHour,
            hydrationMlPerHour: hydrationMlPerHour,
            sodiumMgPerHour: sodiumMgPerHour,
            hydrationIntervalSeconds: hydrationIntervalSeconds,
            fuelIntervalSeconds: fuelIntervalSeconds,
            electrolyteIntervalSeconds: electrolyteIntervalSeconds,
            entries: entryData
        )

        let key = "clip.nutritionPlan.\(raceId.uuidString)"
        do {
            let data = try JSONEncoder().encode(clipData)
            defaults.set(data, forKey: key)
            Logger.persistence.info("Wrote clip nutrition data for race \(raceId)")
        } catch {
            Logger.persistence.error("Failed to encode clip nutrition data for race \(raceId): \(error)")
        }
    }
}

// MARK: - DTOs (mirrors ClipNutritionPlanData in the Clip target)

private struct ClipNutritionPlanDTO: Codable {
    let raceId: UUID
    let raceName: String
    let caloriesPerHour: Int
    let hydrationMlPerHour: Int
    let sodiumMgPerHour: Int
    let hydrationIntervalSeconds: TimeInterval
    let fuelIntervalSeconds: TimeInterval
    let electrolyteIntervalSeconds: TimeInterval
    let entries: [ClipNutritionEntryDTO]
}

private struct ClipNutritionEntryDTO: Codable {
    let id: UUID
    let productName: String
    let timingMinutes: Int
    let quantity: Int
    let calories: Int
}
