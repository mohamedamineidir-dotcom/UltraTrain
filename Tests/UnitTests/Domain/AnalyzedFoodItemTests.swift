import Foundation
import Testing
@testable import UltraTrain

@Suite("Analyzed food item macro cross-updating")
struct AnalyzedFoodItemTests {

    private func makeItem(
        portion: Double = 200, calories: Int = 320, carbs: Double = 40, protein: Double = 6, fat: Double = 8
    ) -> AnalyzedFoodItem {
        AnalyzedFoodItem(
            id: UUID(), name: "Test Food", portionGrams: portion,
            calories: calories, carbsGrams: carbs, proteinGrams: protein, fatGrams: fat
        )
    }

    @Test("Scaling by half halves calories and all three macros")
    func scaleByHalf() {
        var item = makeItem()
        item.scale(by: 0.5)
        #expect(item.calories == 160)
        #expect(item.carbsGrams == 20)
        #expect(item.proteinGrams == 3)
        #expect(item.fatGrams == 4)
    }

    @Test("Editing portion scales calories and macros proportionally")
    func portionEditScalesEverything() {
        var item = makeItem(portion: 200, calories: 320, carbs: 40, protein: 6, fat: 8)
        // Portion 200g -> 100g is a 0.5 ratio, same as scaleByHalf but
        // driven through the same math the UI's portion stepper uses.
        let ratio = 100.0 / item.portionGrams
        item.scale(by: ratio)
        item.portionGrams = 100
        #expect(item.portionGrams == 100)
        #expect(item.calories == 160)
        #expect(item.carbsGrams == 20)
    }

    @Test("Editing a macro recalculates calories via Atwater factors, leaving other macros untouched")
    func macroEditRecalculatesCalories() {
        var item = makeItem(portion: 200, calories: 320, carbs: 40, protein: 6, fat: 8)
        item.carbsGrams = 20 // athlete corrects carbs downward
        item.recalculateCaloriesFromMacros()
        // 20*4 (carbs) + 6*4 (protein) + 8*9 (fat) = 80 + 24 + 72 = 176
        #expect(item.calories == 176)
        #expect(item.proteinGrams == 6, "Editing carbs shouldn't touch protein")
        #expect(item.fatGrams == 8, "Editing carbs shouldn't touch fat")
        #expect(item.portionGrams == 200, "Editing a macro shouldn't touch portion")
    }

    @Test("Editing calories scales portion and all macros by the same ratio")
    func calorieEditScalesEverything() {
        var item = makeItem(portion: 200, calories: 320, carbs: 40, protein: 6, fat: 8)
        let newCalories = 160
        let ratio = Double(newCalories) / Double(item.calories)
        item.scale(by: ratio)
        item.calories = newCalories
        #expect(item.calories == 160)
        #expect(item.carbsGrams == 20)
        #expect(item.proteinGrams == 3)
        #expect(item.fatGrams == 4)
    }
}
