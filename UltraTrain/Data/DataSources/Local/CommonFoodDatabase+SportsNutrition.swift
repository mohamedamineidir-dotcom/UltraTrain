import Foundation

// MARK: - Sports Nutrition Products (Branded + Generic)

extension CommonFoodDatabase {

    // swiftlint:disable:next function_body_length
    static let sportsNutritionProducts: [FoodEntry] = {
        var items: [FoodEntry] = []

        // MARK: Generic Sports Nutrition
        items.append(contentsOf: [
            FoodEntry(name: "Energy Gel", nameFr: "Gel énergétique", brand: "Generic", caloriesPer100g: 250, carbsPer100g: 62.5, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 200, servingSizeGrams: 40, category: "Sports"),
            FoodEntry(name: "Energy Gel (Caffeinated)", nameFr: "Gel caféiné", brand: "Generic", caloriesPer100g: 250, carbsPer100g: 62.5, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 200, servingSizeGrams: 40, category: "Sports"),
            FoodEntry(name: "Energy Bar", nameFr: "Barre énergétique", brand: "Generic", caloriesPer100g: 350, carbsPer100g: 50.0, proteinPer100g: 10.0, fatPer100g: 12.0, sodiumMgPer100g: 200, servingSizeGrams: 55, category: "Sports"),
            FoodEntry(name: "Energy Chews", nameFr: "Gommes énergétiques", brand: "Generic", caloriesPer100g: 312, carbsPer100g: 78.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 156, servingSizeGrams: 50, category: "Sports"),
            FoodEntry(name: "Electrolyte Powder", nameFr: "Poudre d'électrolytes", brand: "Generic", caloriesPer100g: 100, carbsPer100g: 25.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 5000, servingSizeGrams: 10, category: "Sports"),
            FoodEntry(name: "Electrolyte Tablets", nameFr: "Pastilles d'électrolytes", brand: "Generic", caloriesPer100g: 50, carbsPer100g: 12.5, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 7500, servingSizeGrams: 4, category: "Sports"),
            FoodEntry(name: "Maltodextrin Powder", nameFr: "Maltodextrine", brand: "Generic", caloriesPer100g: 380, carbsPer100g: 95.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 10, servingSizeGrams: 30, category: "Sports"),
            FoodEntry(name: "Isotonic Drink Mix", nameFr: "Boisson isotonique", brand: "Generic", caloriesPer100g: 160, carbsPer100g: 40.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 2000, servingSizeGrams: 40, category: "Sports"),
            FoodEntry(name: "Recovery Drink Mix", nameFr: "Boisson de récupération", brand: "Generic", caloriesPer100g: 300, carbsPer100g: 50.0, proteinPer100g: 15.0, fatPer100g: 3.0, sodiumMgPer100g: 300, servingSizeGrams: 50, category: "Sports"),
            FoodEntry(name: "Protein Bar", nameFr: "Barre protéinée", brand: "Generic", caloriesPer100g: 370, carbsPer100g: 30.0, proteinPer100g: 30.0, fatPer100g: 12.0, sodiumMgPer100g: 250, servingSizeGrams: 60, category: "Sports"),
            FoodEntry(name: "Mass Gainer", nameFr: "Gainer", brand: "Generic", caloriesPer100g: 380, carbsPer100g: 65.0, proteinPer100g: 20.0, fatPer100g: 5.0, sodiumMgPer100g: 150, servingSizeGrams: 150, category: "Sports"),
            FoodEntry(name: "BCAA Powder", nameFr: "BCAA en poudre", brand: "Generic", caloriesPer100g: 0, carbsPer100g: 0.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 0, servingSizeGrams: 10, category: "Sports"),
            FoodEntry(name: "Creatine Monohydrate", nameFr: "Créatine monohydrate", brand: "Generic", caloriesPer100g: 0, carbsPer100g: 0.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 0, servingSizeGrams: 5, category: "Sports"),
        ])

        // MARK: Gels — Branded
        items.append(contentsOf: [
            FoodEntry(name: "GU Energy Gel", nameFr: nil, brand: "GU", caloriesPer100g: 312, carbsPer100g: 68.8, proteinPer100g: 0.0, fatPer100g: 3.1, sodiumMgPer100g: 172, servingSizeGrams: 32, category: "Sports"),
            FoodEntry(name: "GU Roctane Gel", nameFr: nil, brand: "GU", caloriesPer100g: 312, carbsPer100g: 65.6, proteinPer100g: 0.0, fatPer100g: 3.1, sodiumMgPer100g: 390, servingSizeGrams: 32, category: "Sports"),
            FoodEntry(name: "GU Roctane Gel (Caffeine)", nameFr: nil, brand: "GU", caloriesPer100g: 312, carbsPer100g: 65.6, proteinPer100g: 0.0, fatPer100g: 3.1, sodiumMgPer100g: 390, servingSizeGrams: 32, category: "Sports"),
            FoodEntry(name: "Maurten Gel 100", nameFr: nil, brand: "Maurten", caloriesPer100g: 250, carbsPer100g: 62.5, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 50, servingSizeGrams: 40, category: "Sports"),
            FoodEntry(name: "Maurten Gel 100 CAF 100", nameFr: nil, brand: "Maurten", caloriesPer100g: 250, carbsPer100g: 62.5, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 50, servingSizeGrams: 40, category: "Sports"),
            FoodEntry(name: "Maurten Gel 160", nameFr: nil, brand: "Maurten", caloriesPer100g: 320, carbsPer100g: 80.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 40, servingSizeGrams: 50, category: "Sports"),
            FoodEntry(name: "SIS GO Isotonic Gel", nameFr: nil, brand: "Science in Sport", caloriesPer100g: 145, carbsPer100g: 36.7, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 17, servingSizeGrams: 60, category: "Sports"),
            FoodEntry(name: "SIS GO Isotonic Gel + Caffeine", nameFr: nil, brand: "Science in Sport", caloriesPer100g: 145, carbsPer100g: 36.7, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 17, servingSizeGrams: 60, category: "Sports"),
            FoodEntry(name: "SIS Beta Fuel Gel", nameFr: nil, brand: "Science in Sport", caloriesPer100g: 307, carbsPer100g: 76.7, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 33, servingSizeGrams: 60, category: "Sports"),
            FoodEntry(name: "Honey Stinger Organic Gel", nameFr: nil, brand: "Honey Stinger", caloriesPer100g: 312, carbsPer100g: 75.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 156, servingSizeGrams: 32, category: "Sports"),
            FoodEntry(name: "Spring Energy Awesome Sauce", nameFr: nil, brand: "Spring Energy", caloriesPer100g: 222, carbsPer100g: 44.4, proteinPer100g: 4.4, fatPer100g: 2.2, sodiumMgPer100g: 89, servingSizeGrams: 45, category: "Sports"),
            FoodEntry(name: "Spring Energy Canaberry", nameFr: nil, brand: "Spring Energy", caloriesPer100g: 360, carbsPer100g: 66.0, proteinPer100g: 8.0, fatPer100g: 6.0, sodiumMgPer100g: 100, servingSizeGrams: 50, category: "Sports"),
            FoodEntry(name: "Spring Energy Speednut", nameFr: nil, brand: "Spring Energy", caloriesPer100g: 400, carbsPer100g: 56.0, proteinPer100g: 8.0, fatPer100g: 16.0, sodiumMgPer100g: 110, servingSizeGrams: 50, category: "Sports"),
            FoodEntry(name: "Spring Energy Hill Aid", nameFr: nil, brand: "Spring Energy", caloriesPer100g: 455, carbsPer100g: 69.1, proteinPer100g: 9.1, fatPer100g: 14.5, sodiumMgPer100g: 109, servingSizeGrams: 55, category: "Sports"),
            FoodEntry(name: "PowerBar PowerGel", nameFr: nil, brand: "PowerBar", caloriesPer100g: 268, carbsPer100g: 65.9, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 488, servingSizeGrams: 41, category: "Sports"),
            FoodEntry(name: "Hammer Gel", nameFr: nil, brand: "Hammer Nutrition", caloriesPer100g: 273, carbsPer100g: 63.6, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 61, servingSizeGrams: 33, category: "Sports"),
            FoodEntry(name: "Precision Fuel PF 30 Gel", nameFr: nil, brand: "Precision Fuel", caloriesPer100g: 235, carbsPer100g: 58.8, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 392, servingSizeGrams: 51, category: "Sports"),
            FoodEntry(name: "Precision Fuel PF 30 Caffeine Gel", nameFr: nil, brand: "Precision Fuel", caloriesPer100g: 235, carbsPer100g: 58.8, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 392, servingSizeGrams: 51, category: "Sports"),
            FoodEntry(name: "Overstim's Coup de Fouet", nameFr: nil, brand: "Overstim's", caloriesPer100g: 290, carbsPer100g: 66.7, proteinPer100g: 0.0, fatPer100g: 1.7, sodiumMgPer100g: 100, servingSizeGrams: 30, category: "Sports"),
            FoodEntry(name: "Overstim's Antioxydant Gel", nameFr: nil, brand: "Overstim's", caloriesPer100g: 283, carbsPer100g: 63.3, proteinPer100g: 0.0, fatPer100g: 1.0, sodiumMgPer100g: 67, servingSizeGrams: 30, category: "Sports"),
            FoodEntry(name: "Huma Chia Energy Gel", nameFr: nil, brand: "Huma", caloriesPer100g: 256, carbsPer100g: 56.4, proteinPer100g: 2.6, fatPer100g: 3.8, sodiumMgPer100g: 64, servingSizeGrams: 39, category: "Sports"),
            FoodEntry(name: "Huma Plus Gel", nameFr: nil, brand: "Huma", caloriesPer100g: 279, carbsPer100g: 62.8, proteinPer100g: 2.3, fatPer100g: 2.3, sodiumMgPer100g: 581, servingSizeGrams: 43, category: "Sports"),
            FoodEntry(name: "Näak Ultra Energy Gel", nameFr: nil, brand: "Näak", caloriesPer100g: 211, carbsPer100g: 47.4, proteinPer100g: 3.5, fatPer100g: 1.8, sodiumMgPer100g: 175, servingSizeGrams: 57, category: "Sports"),
            FoodEntry(name: "Clif Shot Gel", nameFr: nil, brand: "Clif", caloriesPer100g: 294, carbsPer100g: 70.6, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 176, servingSizeGrams: 34, category: "Sports"),
            FoodEntry(name: "Aptonia ISO Gel", nameFr: nil, brand: "Aptonia", caloriesPer100g: 250, carbsPer100g: 61.1, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 111, servingSizeGrams: 36, category: "Sports"),
            FoodEntry(name: "Nduranz Nrgy Gel", nameFr: nil, brand: "Nduranz", caloriesPer100g: 249, carbsPer100g: 62.2, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 222, servingSizeGrams: 45, category: "Sports"),
        ])

        // MARK: Bars — Branded
        items.append(contentsOf: [
            FoodEntry(name: "Clif Bar", nameFr: nil, brand: "Clif", caloriesPer100g: 368, carbsPer100g: 64.7, proteinPer100g: 14.7, fatPer100g: 8.8, sodiumMgPer100g: 382, servingSizeGrams: 68, category: "Sports"),
            FoodEntry(name: "Maurten Solid 225", nameFr: nil, brand: "Maurten", caloriesPer100g: 375, carbsPer100g: 75.0, proteinPer100g: 5.0, fatPer100g: 5.8, sodiumMgPer100g: 80, servingSizeGrams: 60, category: "Sports"),
            FoodEntry(name: "Maurten Solid 160", nameFr: nil, brand: "Maurten", caloriesPer100g: 356, carbsPer100g: 77.8, proteinPer100g: 4.4, fatPer100g: 4.4, sodiumMgPer100g: 80, servingSizeGrams: 45, category: "Sports"),
            FoodEntry(name: "SIS GO Energy Bar", nameFr: nil, brand: "Science in Sport", caloriesPer100g: 377, carbsPer100g: 61.5, proteinPer100g: 6.2, fatPer100g: 10.8, sodiumMgPer100g: 100, servingSizeGrams: 65, category: "Sports"),
            FoodEntry(name: "Skratch Labs Anytime Energy Bar", nameFr: nil, brand: "Skratch Labs", caloriesPer100g: 380, carbsPer100g: 60.0, proteinPer100g: 8.0, fatPer100g: 12.0, sodiumMgPer100g: 120, servingSizeGrams: 50, category: "Sports"),
            FoodEntry(name: "Näak Ultra Energy Bar", nameFr: nil, brand: "Näak", caloriesPer100g: 369, carbsPer100g: 50.8, proteinPer100g: 10.8, fatPer100g: 13.8, sodiumMgPer100g: 215, servingSizeGrams: 65, category: "Sports"),
            FoodEntry(name: "PowerBar Energize C2MAX", nameFr: nil, brand: "PowerBar", caloriesPer100g: 376, carbsPer100g: 69.1, proteinPer100g: 5.5, fatPer100g: 7.3, sodiumMgPer100g: 218, servingSizeGrams: 55, category: "Sports"),
            FoodEntry(name: "Overstim's Energix Bar", nameFr: nil, brand: "Overstim's", caloriesPer100g: 383, carbsPer100g: 63.3, proteinPer100g: 6.7, fatPer100g: 10.0, sodiumMgPer100g: 50, servingSizeGrams: 30, category: "Sports"),
            FoodEntry(name: "Aptonia Ultra Bar", nameFr: nil, brand: "Aptonia", caloriesPer100g: 375, carbsPer100g: 60.0, proteinPer100g: 7.5, fatPer100g: 10.0, sodiumMgPer100g: 125, servingSizeGrams: 40, category: "Sports"),
            FoodEntry(name: "Kind Bar (Nuts & Sea Salt)", nameFr: nil, brand: "Kind", caloriesPer100g: 500, carbsPer100g: 40.0, proteinPer100g: 15.0, fatPer100g: 37.5, sodiumMgPer100g: 350, servingSizeGrams: 40, category: "Sports"),
            FoodEntry(name: "RX Bar", nameFr: nil, brand: "RX", caloriesPer100g: 404, carbsPer100g: 44.2, proteinPer100g: 23.1, fatPer100g: 17.3, sodiumMgPer100g: 385, servingSizeGrams: 52, category: "Sports"),
            FoodEntry(name: "Larabar", nameFr: nil, brand: "Larabar", caloriesPer100g: 489, carbsPer100g: 53.3, proteinPer100g: 11.1, fatPer100g: 28.9, sodiumMgPer100g: 11, servingSizeGrams: 45, category: "Sports"),
        ])

        // MARK: Drink Mixes — Branded
        items.append(contentsOf: [
            FoodEntry(name: "Maurten Drink Mix 160", nameFr: nil, brand: "Maurten", caloriesPer100g: 400, carbsPer100g: 97.5, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 250, servingSizeGrams: 40, category: "Sports"),
            FoodEntry(name: "Maurten Drink Mix 320", nameFr: nil, brand: "Maurten", caloriesPer100g: 400, carbsPer100g: 98.8, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 250, servingSizeGrams: 80, category: "Sports"),
            FoodEntry(name: "Tailwind Endurance Fuel", nameFr: nil, brand: "Tailwind", caloriesPer100g: 370, carbsPer100g: 92.6, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 1122, servingSizeGrams: 27, category: "Sports"),
            FoodEntry(name: "Skratch Labs Sport Hydration Mix", nameFr: nil, brand: "Skratch Labs", caloriesPer100g: 364, carbsPer100g: 90.9, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 1727, servingSizeGrams: 22, category: "Sports"),
            FoodEntry(name: "Skratch Labs Super High-Carb Mix", nameFr: nil, brand: "Skratch Labs", caloriesPer100g: 357, carbsPer100g: 89.3, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 679, servingSizeGrams: 56, category: "Sports"),
            FoodEntry(name: "SIS GO Electrolyte Powder", nameFr: nil, brand: "Science in Sport", caloriesPer100g: 350, carbsPer100g: 90.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 750, servingSizeGrams: 40, category: "Sports"),
            FoodEntry(name: "Overstim's Hydrixir", nameFr: nil, brand: "Overstim's", caloriesPer100g: 333, carbsPer100g: 83.3, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 1000, servingSizeGrams: 30, category: "Sports"),
            FoodEntry(name: "Aptonia ISO Drink", nameFr: nil, brand: "Aptonia", caloriesPer100g: 360, carbsPer100g: 88.6, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 857, servingSizeGrams: 35, category: "Sports"),
            FoodEntry(name: "Näak Ultra Drink Mix", nameFr: nil, brand: "Näak", caloriesPer100g: 375, carbsPer100g: 86.1, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 472, servingSizeGrams: 72, category: "Sports"),
            FoodEntry(name: "Hammer HEED", nameFr: nil, brand: "Hammer Nutrition", caloriesPer100g: 357, carbsPer100g: 89.3, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 143, servingSizeGrams: 28, category: "Sports"),
            FoodEntry(name: "Tailwind Rebuild Recovery", nameFr: nil, brand: "Tailwind", caloriesPer100g: 408, carbsPer100g: 65.3, proteinPer100g: 20.4, fatPer100g: 6.1, sodiumMgPer100g: 612, servingSizeGrams: 49, category: "Sports"),
        ])

        // MARK: Chews & Waffles — Branded
        items.append(contentsOf: [
            FoodEntry(name: "GU Energy Chews", nameFr: nil, brand: "GU", caloriesPer100g: 296, carbsPer100g: 66.7, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 74, servingSizeGrams: 54, category: "Sports"),
            FoodEntry(name: "Clif Bloks", nameFr: nil, brand: "Clif", caloriesPer100g: 300, carbsPer100g: 75.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 117, servingSizeGrams: 60, category: "Sports"),
            FoodEntry(name: "Honey Stinger Organic Chews", nameFr: nil, brand: "Honey Stinger", caloriesPer100g: 320, carbsPer100g: 78.0, proteinPer100g: 2.0, fatPer100g: 0.0, sodiumMgPer100g: 140, servingSizeGrams: 50, category: "Sports"),
            FoodEntry(name: "Skratch Labs Energy Chews", nameFr: nil, brand: "Skratch Labs", caloriesPer100g: 320, carbsPer100g: 80.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 160, servingSizeGrams: 50, category: "Sports"),
            FoodEntry(name: "Honey Stinger Waffle", nameFr: nil, brand: "Honey Stinger", caloriesPer100g: 467, carbsPer100g: 70.0, proteinPer100g: 3.3, fatPer100g: 20.0, sodiumMgPer100g: 183, servingSizeGrams: 30, category: "Sports"),
            FoodEntry(name: "GU Stroopwafel", nameFr: nil, brand: "GU", caloriesPer100g: 469, carbsPer100g: 65.6, proteinPer100g: 6.3, fatPer100g: 18.8, sodiumMgPer100g: 109, servingSizeGrams: 32, category: "Sports"),
        ])

        // MARK: Electrolytes & Salt Capsules — Branded
        items.append(contentsOf: [
            FoodEntry(name: "Nuun Sport", nameFr: nil, brand: "Nuun", caloriesPer100g: 273, carbsPer100g: 72.7, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 5455, servingSizeGrams: 5.5, category: "Sports"),
            FoodEntry(name: "Nuun Endurance", nameFr: nil, brand: "Nuun", caloriesPer100g: 400, carbsPer100g: 100.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 2533, servingSizeGrams: 15, category: "Sports"),
            FoodEntry(name: "LMNT Electrolyte Mix", nameFr: nil, brand: "LMNT", caloriesPer100g: 0, carbsPer100g: 0.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 16667, servingSizeGrams: 6, category: "Sports"),
            FoodEntry(name: "SaltStick Caps", nameFr: nil, brand: "SaltStick", caloriesPer100g: 0, carbsPer100g: 0.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 21500, servingSizeGrams: 1, category: "Sports"),
            FoodEntry(name: "Precision Fuel PH 1000", nameFr: nil, brand: "Precision Fuel", caloriesPer100g: 375, carbsPer100g: 87.5, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 6250, servingSizeGrams: 8, category: "Sports"),
            FoodEntry(name: "Precision Fuel PH 1500", nameFr: nil, brand: "Precision Fuel", caloriesPer100g: 375, carbsPer100g: 87.5, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 9375, servingSizeGrams: 8, category: "Sports"),
            FoodEntry(name: "Hammer Endurolytes", nameFr: nil, brand: "Hammer Nutrition", caloriesPer100g: 0, carbsPer100g: 0.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 5714, servingSizeGrams: 1.4, category: "Sports"),
            FoodEntry(name: "SIS GO Hydro Tablet", nameFr: nil, brand: "Science in Sport", caloriesPer100g: 238, carbsPer100g: 47.6, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 8214, servingSizeGrams: 4.2, category: "Sports"),
        ])

        return items
    }()
}
