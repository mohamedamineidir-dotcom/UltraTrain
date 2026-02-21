import Foundation
import Testing
@testable import UltraTrain

@Suite("Live Nutrition Tracker Tests")
struct LiveNutritionTrackerTests {

    // MARK: - Helpers

    private func makeEntry(
        type: NutritionReminderType = .fuel,
        status: NutritionIntakeStatus = .taken,
        elapsedTime: TimeInterval = 1800,
        calories: Int? = nil,
        carbs: Double? = nil,
        sodium: Int? = nil,
        isManual: Bool = false
    ) -> NutritionIntakeEntry {
        NutritionIntakeEntry(
            reminderType: type,
            status: status,
            elapsedTimeSeconds: elapsedTime,
            message: "Test",
            caloriesConsumed: calories,
            carbsGramsConsumed: carbs,
            sodiumMgConsumed: sodium,
            isManualEntry: isManual
        )
    }

    private func makeProduct(
        name: String = "Test Gel",
        type: ProductType = .gel,
        calories: Int = 100,
        carbs: Double = 25,
        sodium: Int = 50
    ) -> NutritionProduct {
        NutritionProduct(
            id: UUID(),
            name: name,
            type: type,
            caloriesPerServing: calories,
            carbsGramsPerServing: carbs,
            sodiumMgPerServing: sodium,
            caffeinated: false
        )
    }

    // MARK: - Calculate Totals

    @Test("Empty log returns zeros")
    func emptyLogReturnsZeros() {
        let totals = LiveNutritionTracker.calculateTotals(from: [], elapsedTime: 3600)
        #expect(totals.totalCalories == 0)
        #expect(totals.totalCarbsGrams == 0)
        #expect(totals.hydrationCount == 0)
    }

    @Test("Totals with product data sums correctly")
    func totalsWithProductData() {
        let entries = [
            makeEntry(type: .fuel, calories: 100, carbs: 25, sodium: 50),
            makeEntry(type: .fuel, calories: 80, carbs: 20, sodium: 30),
        ]
        let totals = LiveNutritionTracker.calculateTotals(from: entries, elapsedTime: 3600)
        #expect(totals.totalCalories == 180)
        #expect(totals.totalCarbsGrams == 45)
        #expect(totals.totalSodiumMg == 80)
        #expect(totals.fuelCount == 2)
    }

    @Test("Mixed entries uses product data when available")
    func mixedEntries() {
        let entries = [
            makeEntry(type: .fuel, calories: 100),
            makeEntry(type: .fuel),
        ]
        let totals = LiveNutritionTracker.calculateTotals(from: entries, elapsedTime: 3600)
        #expect(totals.totalCalories == 125)
    }

    @Test("Calories per hour calculated correctly")
    func caloriesPerHour() {
        let entries = [
            makeEntry(type: .fuel, calories: 200),
        ]
        let totals = LiveNutritionTracker.calculateTotals(from: entries, elapsedTime: 7200)
        #expect(totals.caloriesPerHour == 100)
    }

    @Test("Only counts taken entries")
    func onlyCountsTaken() {
        let entries = [
            makeEntry(status: .taken, calories: 100),
            makeEntry(status: .skipped, calories: 100),
            makeEntry(status: .pending, calories: 100),
        ]
        let totals = LiveNutritionTracker.calculateTotals(from: entries, elapsedTime: 3600)
        #expect(totals.totalCalories == 100)
        #expect(totals.fuelCount == 1)
    }

    // MARK: - Build Manual Entry

    @Test("Gel sets fuel type")
    func gelSetsFuelType() {
        let product = makeProduct(type: .gel)
        let entry = LiveNutritionTracker.buildManualEntry(product: product, elapsedTime: 1800)
        #expect(entry.reminderType == .fuel)
        #expect(entry.isManualEntry == true)
    }

    @Test("Drink sets hydration type")
    func drinkSetsHydrationType() {
        let product = makeProduct(type: .drink)
        let entry = LiveNutritionTracker.buildManualEntry(product: product, elapsedTime: 1800)
        #expect(entry.reminderType == .hydration)
    }

    @Test("Salt sets electrolyte type")
    func saltSetsElectrolyteType() {
        let product = makeProduct(type: .salt)
        let entry = LiveNutritionTracker.buildManualEntry(product: product, elapsedTime: 1800)
        #expect(entry.reminderType == .electrolyte)
    }

    @Test("Manual entry sets isManual true")
    func isManualEntryTrue() {
        let product = makeProduct()
        let entry = LiveNutritionTracker.buildManualEntry(product: product, elapsedTime: 1800)
        #expect(entry.isManualEntry == true)
        #expect(entry.productId == product.id)
        #expect(entry.productName == product.name)
    }

    @Test("Quantity multiplies values")
    func quantityMultiplies() {
        let product = makeProduct(calories: 100, carbs: 25, sodium: 50)
        let entry = LiveNutritionTracker.buildManualEntry(product: product, elapsedTime: 1800, quantity: 3)
        #expect(entry.caloriesConsumed == 300)
        #expect(entry.carbsGramsConsumed == 75)
        #expect(entry.sodiumMgConsumed == 150)
    }
}
