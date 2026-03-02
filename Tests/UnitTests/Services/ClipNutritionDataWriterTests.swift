import Foundation
import Testing
@testable import UltraTrain

@Suite("ClipNutritionDataWriter Tests")
struct ClipNutritionDataWriterTests {

    private let suiteName = "group.com.ultratrain.shared"

    @Test("Writes nutrition plan data to shared UserDefaults")
    func writeNutritionPlan() {
        let raceId = UUID()
        ClipNutritionDataWriter.writeNutritionPlan(
            raceId: raceId,
            raceName: "UTMB 2026",
            caloriesPerHour: 300,
            hydrationMlPerHour: 500,
            sodiumMgPerHour: 600,
            hydrationIntervalSeconds: 900,
            fuelIntervalSeconds: 1800,
            electrolyteIntervalSeconds: 2700,
            entries: [
                (id: UUID(), productName: "Gel", timingMinutes: 30, quantity: 1, calories: 100)
            ]
        )

        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to access shared app group")
            return
        }

        let key = "clip.nutritionPlan.\(raceId.uuidString)"
        let data = defaults.data(forKey: key)
        #expect(data != nil)

        // Clean up
        defaults.removeObject(forKey: key)
    }

    @Test("Written data is decodable with expected values")
    func roundTripDecode() throws {
        let raceId = UUID()
        let entryId = UUID()

        ClipNutritionDataWriter.writeNutritionPlan(
            raceId: raceId,
            raceName: "CCC",
            caloriesPerHour: 250,
            hydrationMlPerHour: 600,
            sodiumMgPerHour: 700,
            hydrationIntervalSeconds: 1200,
            fuelIntervalSeconds: 1500,
            electrolyteIntervalSeconds: 3000,
            entries: [
                (id: entryId, productName: "Bar", timingMinutes: 45, quantity: 2, calories: 200)
            ]
        )

        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let key = "clip.nutritionPlan.\(raceId.uuidString)"
        let data = try #require(defaults.data(forKey: key))

        // Decode using a mirrored structure to validate
        let decoded = try JSONDecoder().decode(ClipNutritionPlanTestDTO.self, from: data)
        #expect(decoded.raceId == raceId)
        #expect(decoded.raceName == "CCC")
        #expect(decoded.caloriesPerHour == 250)
        #expect(decoded.hydrationMlPerHour == 600)
        #expect(decoded.sodiumMgPerHour == 700)
        #expect(decoded.hydrationIntervalSeconds == 1200)
        #expect(decoded.fuelIntervalSeconds == 1500)
        #expect(decoded.electrolyteIntervalSeconds == 3000)
        #expect(decoded.entries.count == 1)
        #expect(decoded.entries[0].id == entryId)
        #expect(decoded.entries[0].productName == "Bar")
        #expect(decoded.entries[0].timingMinutes == 45)
        #expect(decoded.entries[0].quantity == 2)
        #expect(decoded.entries[0].calories == 200)

        // Clean up
        defaults.removeObject(forKey: key)
    }

    @Test("Multiple entries are preserved")
    func multipleEntries() throws {
        let raceId = UUID()

        ClipNutritionDataWriter.writeNutritionPlan(
            raceId: raceId,
            raceName: "TDS",
            caloriesPerHour: 300,
            hydrationMlPerHour: 500,
            sodiumMgPerHour: 600,
            hydrationIntervalSeconds: 900,
            fuelIntervalSeconds: 1800,
            electrolyteIntervalSeconds: 2700,
            entries: [
                (id: UUID(), productName: "Gel A", timingMinutes: 30, quantity: 1, calories: 100),
                (id: UUID(), productName: "Bar B", timingMinutes: 60, quantity: 2, calories: 250),
                (id: UUID(), productName: "Drink C", timingMinutes: 15, quantity: 1, calories: 50)
            ]
        )

        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let key = "clip.nutritionPlan.\(raceId.uuidString)"
        let data = try #require(defaults.data(forKey: key))

        let decoded = try JSONDecoder().decode(ClipNutritionPlanTestDTO.self, from: data)
        #expect(decoded.entries.count == 3)
        #expect(decoded.entries[0].productName == "Gel A")
        #expect(decoded.entries[1].productName == "Bar B")
        #expect(decoded.entries[2].productName == "Drink C")

        // Clean up
        defaults.removeObject(forKey: key)
    }

    @Test("Writing for different races uses separate keys")
    func separateRaceKeys() throws {
        let raceId1 = UUID()
        let raceId2 = UUID()

        ClipNutritionDataWriter.writeNutritionPlan(
            raceId: raceId1, raceName: "Race 1",
            caloriesPerHour: 300, hydrationMlPerHour: 500, sodiumMgPerHour: 600,
            hydrationIntervalSeconds: 900, fuelIntervalSeconds: 1800, electrolyteIntervalSeconds: 2700,
            entries: []
        )
        ClipNutritionDataWriter.writeNutritionPlan(
            raceId: raceId2, raceName: "Race 2",
            caloriesPerHour: 350, hydrationMlPerHour: 550, sodiumMgPerHour: 650,
            hydrationIntervalSeconds: 1000, fuelIntervalSeconds: 2000, electrolyteIntervalSeconds: 3000,
            entries: []
        )

        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let data1 = try #require(defaults.data(forKey: "clip.nutritionPlan.\(raceId1.uuidString)"))
        let data2 = try #require(defaults.data(forKey: "clip.nutritionPlan.\(raceId2.uuidString)"))

        let decoded1 = try JSONDecoder().decode(ClipNutritionPlanTestDTO.self, from: data1)
        let decoded2 = try JSONDecoder().decode(ClipNutritionPlanTestDTO.self, from: data2)

        #expect(decoded1.raceName == "Race 1")
        #expect(decoded2.raceName == "Race 2")
        #expect(decoded1.caloriesPerHour == 300)
        #expect(decoded2.caloriesPerHour == 350)

        // Clean up
        defaults.removeObject(forKey: "clip.nutritionPlan.\(raceId1.uuidString)")
        defaults.removeObject(forKey: "clip.nutritionPlan.\(raceId2.uuidString)")
    }
}

// MARK: - Test DTO (mirrors the private DTO in ClipNutritionDataWriter)

private struct ClipNutritionPlanTestDTO: Codable {
    let raceId: UUID
    let raceName: String
    let caloriesPerHour: Int
    let hydrationMlPerHour: Int
    let sodiumMgPerHour: Int
    let hydrationIntervalSeconds: TimeInterval
    let fuelIntervalSeconds: TimeInterval
    let electrolyteIntervalSeconds: TimeInterval
    let entries: [ClipNutritionEntryTestDTO]
}

private struct ClipNutritionEntryTestDTO: Codable {
    let id: UUID
    let productName: String
    let timingMinutes: Int
    let quantity: Int
    let calories: Int
}
