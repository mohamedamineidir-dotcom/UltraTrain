import Foundation

enum CommonFoodDatabase {
    struct FoodEntry: Sendable {
        let name: String
        let brand: String?
        let caloriesPer100g: Int
        let carbsPer100g: Double
        let proteinPer100g: Double
        let fatPer100g: Double
        let sodiumMgPer100g: Double
        let servingSizeGrams: Double
        let category: String
    }

    static func search(_ query: String) -> [FoodSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return [] }

        let matches = allFoods.filter { $0.name.lowercased().localizedCaseInsensitiveContains(trimmed) }

        // Prefix matches first, then contains
        let sorted = matches.sorted { a, b in
            let aPrefix = a.name.lowercased().hasPrefix(trimmed)
            let bPrefix = b.name.lowercased().hasPrefix(trimmed)
            if aPrefix != bPrefix { return aPrefix }
            return a.name < b.name
        }

        return sorted.map { entry in
            FoodSearchResult(
                id: "local_\(entry.name.lowercased().replacingOccurrences(of: " ", with: "_"))",
                name: entry.name,
                brand: entry.brand,
                caloriesPer100g: entry.caloriesPer100g,
                carbsPer100g: entry.carbsPer100g,
                proteinPer100g: entry.proteinPer100g,
                fatPer100g: entry.fatPer100g,
                sodiumMgPer100g: entry.sodiumMgPer100g,
                servingSizeGrams: entry.servingSizeGrams
            )
        }
    }

    // MARK: - Food Database (~150 common foods)

    // swiftlint:disable function_body_length
    static let allFoods: [FoodEntry] = {
        var foods: [FoodEntry] = []

        // MARK: Grains & Pasta
        foods.append(contentsOf: [
            FoodEntry(name: "Pasta, Cooked", brand: nil, caloriesPer100g: 131, carbsPer100g: 25.0, proteinPer100g: 5.0, fatPer100g: 1.1, sodiumMgPer100g: 1, servingSizeGrams: 200, category: "Grains"),
            FoodEntry(name: "Pasta, Dry", brand: nil, caloriesPer100g: 371, carbsPer100g: 75.0, proteinPer100g: 13.0, fatPer100g: 1.5, sodiumMgPer100g: 6, servingSizeGrams: 80, category: "Grains"),
            FoodEntry(name: "White Rice, Cooked", brand: nil, caloriesPer100g: 130, carbsPer100g: 28.2, proteinPer100g: 2.7, fatPer100g: 0.3, sodiumMgPer100g: 1, servingSizeGrams: 150, category: "Grains"),
            FoodEntry(name: "Brown Rice, Cooked", brand: nil, caloriesPer100g: 123, carbsPer100g: 25.6, proteinPer100g: 2.7, fatPer100g: 1.0, sodiumMgPer100g: 4, servingSizeGrams: 150, category: "Grains"),
            FoodEntry(name: "Oats, Dry", brand: nil, caloriesPer100g: 389, carbsPer100g: 66.3, proteinPer100g: 16.9, fatPer100g: 6.9, sodiumMgPer100g: 2, servingSizeGrams: 40, category: "Grains"),
            FoodEntry(name: "Oatmeal, Cooked", brand: nil, caloriesPer100g: 68, carbsPer100g: 12.0, proteinPer100g: 2.4, fatPer100g: 1.4, sodiumMgPer100g: 49, servingSizeGrams: 240, category: "Grains"),
            FoodEntry(name: "Quinoa, Cooked", brand: nil, caloriesPer100g: 120, carbsPer100g: 21.3, proteinPer100g: 4.4, fatPer100g: 1.9, sodiumMgPer100g: 7, servingSizeGrams: 150, category: "Grains"),
            FoodEntry(name: "Couscous, Cooked", brand: nil, caloriesPer100g: 112, carbsPer100g: 23.2, proteinPer100g: 3.8, fatPer100g: 0.2, sodiumMgPer100g: 5, servingSizeGrams: 150, category: "Grains"),
            FoodEntry(name: "Bread, White", brand: nil, caloriesPer100g: 265, carbsPer100g: 49.0, proteinPer100g: 9.0, fatPer100g: 3.2, sodiumMgPer100g: 491, servingSizeGrams: 30, category: "Grains"),
            FoodEntry(name: "Bread, Whole Wheat", brand: nil, caloriesPer100g: 247, carbsPer100g: 41.3, proteinPer100g: 13.0, fatPer100g: 3.4, sodiumMgPer100g: 400, servingSizeGrams: 30, category: "Grains"),
            FoodEntry(name: "Bagel", brand: nil, caloriesPer100g: 257, carbsPer100g: 50.0, proteinPer100g: 10.0, fatPer100g: 1.6, sodiumMgPer100g: 450, servingSizeGrams: 100, category: "Grains"),
            FoodEntry(name: "Tortilla, Flour", brand: nil, caloriesPer100g: 312, carbsPer100g: 51.6, proteinPer100g: 8.2, fatPer100g: 8.4, sodiumMgPer100g: 570, servingSizeGrams: 45, category: "Grains"),
            FoodEntry(name: "Granola", brand: nil, caloriesPer100g: 489, carbsPer100g: 64.0, proteinPer100g: 10.0, fatPer100g: 20.0, sodiumMgPer100g: 26, servingSizeGrams: 50, category: "Grains"),
            FoodEntry(name: "Cereal, Cornflakes", brand: nil, caloriesPer100g: 357, carbsPer100g: 84.0, proteinPer100g: 7.5, fatPer100g: 0.4, sodiumMgPer100g: 729, servingSizeGrams: 30, category: "Grains"),
            FoodEntry(name: "Noodles, Egg, Cooked", brand: nil, caloriesPer100g: 138, carbsPer100g: 25.2, proteinPer100g: 4.5, fatPer100g: 2.1, sodiumMgPer100g: 5, servingSizeGrams: 200, category: "Grains"),
            FoodEntry(name: "Pancake", brand: nil, caloriesPer100g: 227, carbsPer100g: 28.0, proteinPer100g: 6.4, fatPer100g: 10.0, sodiumMgPer100g: 439, servingSizeGrams: 75, category: "Grains"),
            FoodEntry(name: "Muesli", brand: nil, caloriesPer100g: 340, carbsPer100g: 56.0, proteinPer100g: 10.0, fatPer100g: 8.0, sodiumMgPer100g: 10, servingSizeGrams: 50, category: "Grains"),
            FoodEntry(name: "Polenta, Cooked", brand: nil, caloriesPer100g: 70, carbsPer100g: 15.0, proteinPer100g: 1.6, fatPer100g: 0.3, sodiumMgPer100g: 2, servingSizeGrams: 200, category: "Grains"),
        ])

        // MARK: Proteins
        foods.append(contentsOf: [
            FoodEntry(name: "Chicken Breast, Cooked", brand: nil, caloriesPer100g: 165, carbsPer100g: 0.0, proteinPer100g: 31.0, fatPer100g: 3.6, sodiumMgPer100g: 74, servingSizeGrams: 120, category: "Proteins"),
            FoodEntry(name: "Beef, Lean, Cooked", brand: nil, caloriesPer100g: 250, carbsPer100g: 0.0, proteinPer100g: 26.0, fatPer100g: 15.0, sodiumMgPer100g: 72, servingSizeGrams: 120, category: "Proteins"),
            FoodEntry(name: "Salmon, Cooked", brand: nil, caloriesPer100g: 208, carbsPer100g: 0.0, proteinPer100g: 20.0, fatPer100g: 13.0, sodiumMgPer100g: 59, servingSizeGrams: 125, category: "Proteins"),
            FoodEntry(name: "Tuna, Canned in Water", brand: nil, caloriesPer100g: 116, carbsPer100g: 0.0, proteinPer100g: 25.5, fatPer100g: 0.8, sodiumMgPer100g: 338, servingSizeGrams: 85, category: "Proteins"),
            FoodEntry(name: "Eggs, Whole", brand: nil, caloriesPer100g: 155, carbsPer100g: 1.1, proteinPer100g: 13.0, fatPer100g: 11.0, sodiumMgPer100g: 124, servingSizeGrams: 50, category: "Proteins"),
            FoodEntry(name: "Egg White", brand: nil, caloriesPer100g: 52, carbsPer100g: 0.7, proteinPer100g: 11.0, fatPer100g: 0.2, sodiumMgPer100g: 166, servingSizeGrams: 33, category: "Proteins"),
            FoodEntry(name: "Tofu, Firm", brand: nil, caloriesPer100g: 144, carbsPer100g: 3.0, proteinPer100g: 15.6, fatPer100g: 8.7, sodiumMgPer100g: 14, servingSizeGrams: 100, category: "Proteins"),
            FoodEntry(name: "Turkey Breast, Cooked", brand: nil, caloriesPer100g: 135, carbsPer100g: 0.0, proteinPer100g: 30.0, fatPer100g: 1.0, sodiumMgPer100g: 53, servingSizeGrams: 120, category: "Proteins"),
            FoodEntry(name: "Pork Loin, Cooked", brand: nil, caloriesPer100g: 242, carbsPer100g: 0.0, proteinPer100g: 27.3, fatPer100g: 14.0, sodiumMgPer100g: 51, servingSizeGrams: 120, category: "Proteins"),
            FoodEntry(name: "Lentils, Cooked", brand: nil, caloriesPer100g: 116, carbsPer100g: 20.0, proteinPer100g: 9.0, fatPer100g: 0.4, sodiumMgPer100g: 2, servingSizeGrams: 150, category: "Proteins"),
            FoodEntry(name: "Chickpeas, Cooked", brand: nil, caloriesPer100g: 164, carbsPer100g: 27.4, proteinPer100g: 8.9, fatPer100g: 2.6, sodiumMgPer100g: 7, servingSizeGrams: 150, category: "Proteins"),
            FoodEntry(name: "Black Beans, Cooked", brand: nil, caloriesPer100g: 132, carbsPer100g: 23.7, proteinPer100g: 8.9, fatPer100g: 0.5, sodiumMgPer100g: 1, servingSizeGrams: 150, category: "Proteins"),
            FoodEntry(name: "Shrimp, Cooked", brand: nil, caloriesPer100g: 99, carbsPer100g: 0.2, proteinPer100g: 24.0, fatPer100g: 0.3, sodiumMgPer100g: 111, servingSizeGrams: 85, category: "Proteins"),
            FoodEntry(name: "Cod, Cooked", brand: nil, caloriesPer100g: 105, carbsPer100g: 0.0, proteinPer100g: 23.0, fatPer100g: 0.9, sodiumMgPer100g: 78, servingSizeGrams: 125, category: "Proteins"),
            FoodEntry(name: "Ham, Lean", brand: nil, caloriesPer100g: 145, carbsPer100g: 1.5, proteinPer100g: 21.0, fatPer100g: 5.5, sodiumMgPer100g: 1203, servingSizeGrams: 60, category: "Proteins"),
            FoodEntry(name: "Whey Protein Powder", brand: nil, caloriesPer100g: 400, carbsPer100g: 10.0, proteinPer100g: 75.0, fatPer100g: 5.0, sodiumMgPer100g: 200, servingSizeGrams: 30, category: "Proteins"),
        ])

        // MARK: Fruits
        foods.append(contentsOf: [
            FoodEntry(name: "Banana", brand: nil, caloriesPer100g: 89, carbsPer100g: 22.8, proteinPer100g: 1.1, fatPer100g: 0.3, sodiumMgPer100g: 1, servingSizeGrams: 120, category: "Fruits"),
            FoodEntry(name: "Apple", brand: nil, caloriesPer100g: 52, carbsPer100g: 13.8, proteinPer100g: 0.3, fatPer100g: 0.2, sodiumMgPer100g: 1, servingSizeGrams: 180, category: "Fruits"),
            FoodEntry(name: "Orange", brand: nil, caloriesPer100g: 47, carbsPer100g: 11.8, proteinPer100g: 0.9, fatPer100g: 0.1, sodiumMgPer100g: 0, servingSizeGrams: 130, category: "Fruits"),
            FoodEntry(name: "Strawberries", brand: nil, caloriesPer100g: 32, carbsPer100g: 7.7, proteinPer100g: 0.7, fatPer100g: 0.3, sodiumMgPer100g: 1, servingSizeGrams: 150, category: "Fruits"),
            FoodEntry(name: "Blueberries", brand: nil, caloriesPer100g: 57, carbsPer100g: 14.5, proteinPer100g: 0.7, fatPer100g: 0.3, sodiumMgPer100g: 1, servingSizeGrams: 150, category: "Fruits"),
            FoodEntry(name: "Mango", brand: nil, caloriesPer100g: 60, carbsPer100g: 15.0, proteinPer100g: 0.8, fatPer100g: 0.4, sodiumMgPer100g: 1, servingSizeGrams: 165, category: "Fruits"),
            FoodEntry(name: "Grapes", brand: nil, caloriesPer100g: 69, carbsPer100g: 18.1, proteinPer100g: 0.7, fatPer100g: 0.2, sodiumMgPer100g: 2, servingSizeGrams: 150, category: "Fruits"),
            FoodEntry(name: "Watermelon", brand: nil, caloriesPer100g: 30, carbsPer100g: 7.6, proteinPer100g: 0.6, fatPer100g: 0.2, sodiumMgPer100g: 1, servingSizeGrams: 200, category: "Fruits"),
            FoodEntry(name: "Avocado", brand: nil, caloriesPer100g: 160, carbsPer100g: 8.5, proteinPer100g: 2.0, fatPer100g: 14.7, sodiumMgPer100g: 7, servingSizeGrams: 70, category: "Fruits"),
            FoodEntry(name: "Dates, Medjool", brand: nil, caloriesPer100g: 277, carbsPer100g: 75.0, proteinPer100g: 1.8, fatPer100g: 0.2, sodiumMgPer100g: 1, servingSizeGrams: 24, category: "Fruits"),
            FoodEntry(name: "Pineapple", brand: nil, caloriesPer100g: 50, carbsPer100g: 13.1, proteinPer100g: 0.5, fatPer100g: 0.1, sodiumMgPer100g: 1, servingSizeGrams: 165, category: "Fruits"),
            FoodEntry(name: "Kiwi", brand: nil, caloriesPer100g: 61, carbsPer100g: 14.7, proteinPer100g: 1.1, fatPer100g: 0.5, sodiumMgPer100g: 3, servingSizeGrams: 75, category: "Fruits"),
            FoodEntry(name: "Peach", brand: nil, caloriesPer100g: 39, carbsPer100g: 9.5, proteinPer100g: 0.9, fatPer100g: 0.3, sodiumMgPer100g: 0, servingSizeGrams: 150, category: "Fruits"),
            FoodEntry(name: "Dried Apricots", brand: nil, caloriesPer100g: 241, carbsPer100g: 62.6, proteinPer100g: 3.4, fatPer100g: 0.5, sodiumMgPer100g: 10, servingSizeGrams: 30, category: "Fruits"),
            FoodEntry(name: "Raisins", brand: nil, caloriesPer100g: 299, carbsPer100g: 79.2, proteinPer100g: 3.1, fatPer100g: 0.5, sodiumMgPer100g: 11, servingSizeGrams: 40, category: "Fruits"),
        ])

        // MARK: Vegetables
        foods.append(contentsOf: [
            FoodEntry(name: "Potato, Boiled", brand: nil, caloriesPer100g: 87, carbsPer100g: 20.1, proteinPer100g: 1.9, fatPer100g: 0.1, sodiumMgPer100g: 5, servingSizeGrams: 150, category: "Vegetables"),
            FoodEntry(name: "Sweet Potato, Baked", brand: nil, caloriesPer100g: 90, carbsPer100g: 20.7, proteinPer100g: 2.0, fatPer100g: 0.1, sodiumMgPer100g: 36, servingSizeGrams: 150, category: "Vegetables"),
            FoodEntry(name: "Broccoli, Cooked", brand: nil, caloriesPer100g: 35, carbsPer100g: 7.2, proteinPer100g: 2.4, fatPer100g: 0.4, sodiumMgPer100g: 41, servingSizeGrams: 90, category: "Vegetables"),
            FoodEntry(name: "Spinach, Raw", brand: nil, caloriesPer100g: 23, carbsPer100g: 3.6, proteinPer100g: 2.9, fatPer100g: 0.4, sodiumMgPer100g: 79, servingSizeGrams: 30, category: "Vegetables"),
            FoodEntry(name: "Carrots, Raw", brand: nil, caloriesPer100g: 41, carbsPer100g: 9.6, proteinPer100g: 0.9, fatPer100g: 0.2, sodiumMgPer100g: 69, servingSizeGrams: 80, category: "Vegetables"),
            FoodEntry(name: "Tomato", brand: nil, caloriesPer100g: 18, carbsPer100g: 3.9, proteinPer100g: 0.9, fatPer100g: 0.2, sodiumMgPer100g: 5, servingSizeGrams: 120, category: "Vegetables"),
            FoodEntry(name: "Mushrooms", brand: nil, caloriesPer100g: 22, carbsPer100g: 3.3, proteinPer100g: 3.1, fatPer100g: 0.3, sodiumMgPer100g: 5, servingSizeGrams: 70, category: "Vegetables"),
            FoodEntry(name: "Corn, Cooked", brand: nil, caloriesPer100g: 96, carbsPer100g: 21.0, proteinPer100g: 3.4, fatPer100g: 1.5, sodiumMgPer100g: 1, servingSizeGrams: 150, category: "Vegetables"),
            FoodEntry(name: "Green Peas, Cooked", brand: nil, caloriesPer100g: 84, carbsPer100g: 15.6, proteinPer100g: 5.4, fatPer100g: 0.2, sodiumMgPer100g: 3, servingSizeGrams: 80, category: "Vegetables"),
            FoodEntry(name: "Zucchini, Cooked", brand: nil, caloriesPer100g: 17, carbsPer100g: 3.1, proteinPer100g: 1.2, fatPer100g: 0.3, sodiumMgPer100g: 3, servingSizeGrams: 120, category: "Vegetables"),
            FoodEntry(name: "Bell Pepper, Red", brand: nil, caloriesPer100g: 31, carbsPer100g: 6.0, proteinPer100g: 1.0, fatPer100g: 0.3, sodiumMgPer100g: 4, servingSizeGrams: 120, category: "Vegetables"),
            FoodEntry(name: "Cucumber", brand: nil, caloriesPer100g: 15, carbsPer100g: 3.6, proteinPer100g: 0.7, fatPer100g: 0.1, sodiumMgPer100g: 2, servingSizeGrams: 100, category: "Vegetables"),
            FoodEntry(name: "Lettuce, Mixed Greens", brand: nil, caloriesPer100g: 15, carbsPer100g: 2.9, proteinPer100g: 1.3, fatPer100g: 0.2, sodiumMgPer100g: 28, servingSizeGrams: 50, category: "Vegetables"),
            FoodEntry(name: "Cauliflower, Cooked", brand: nil, caloriesPer100g: 23, carbsPer100g: 4.1, proteinPer100g: 1.8, fatPer100g: 0.5, sodiumMgPer100g: 15, servingSizeGrams: 100, category: "Vegetables"),
            FoodEntry(name: "Onion", brand: nil, caloriesPer100g: 40, carbsPer100g: 9.3, proteinPer100g: 1.1, fatPer100g: 0.1, sodiumMgPer100g: 4, servingSizeGrams: 110, category: "Vegetables"),
        ])

        // MARK: Dairy
        foods.append(contentsOf: [
            FoodEntry(name: "Milk, Whole", brand: nil, caloriesPer100g: 61, carbsPer100g: 4.8, proteinPer100g: 3.2, fatPer100g: 3.3, sodiumMgPer100g: 43, servingSizeGrams: 250, category: "Dairy"),
            FoodEntry(name: "Milk, Semi-Skimmed", brand: nil, caloriesPer100g: 46, carbsPer100g: 4.7, proteinPer100g: 3.4, fatPer100g: 1.5, sodiumMgPer100g: 44, servingSizeGrams: 250, category: "Dairy"),
            FoodEntry(name: "Yogurt, Plain", brand: nil, caloriesPer100g: 61, carbsPer100g: 4.7, proteinPer100g: 3.5, fatPer100g: 3.3, sodiumMgPer100g: 46, servingSizeGrams: 125, category: "Dairy"),
            FoodEntry(name: "Greek Yogurt, Plain", brand: nil, caloriesPer100g: 97, carbsPer100g: 3.6, proteinPer100g: 9.0, fatPer100g: 5.0, sodiumMgPer100g: 47, servingSizeGrams: 170, category: "Dairy"),
            FoodEntry(name: "Greek Yogurt, 0% Fat", brand: nil, caloriesPer100g: 59, carbsPer100g: 3.6, proteinPer100g: 10.0, fatPer100g: 0.4, sodiumMgPer100g: 47, servingSizeGrams: 170, category: "Dairy"),
            FoodEntry(name: "Cottage Cheese", brand: nil, caloriesPer100g: 98, carbsPer100g: 3.4, proteinPer100g: 11.1, fatPer100g: 4.3, sodiumMgPer100g: 364, servingSizeGrams: 110, category: "Dairy"),
            FoodEntry(name: "Cheddar Cheese", brand: nil, caloriesPer100g: 403, carbsPer100g: 1.3, proteinPer100g: 25.0, fatPer100g: 33.1, sodiumMgPer100g: 621, servingSizeGrams: 30, category: "Dairy"),
            FoodEntry(name: "Mozzarella Cheese", brand: nil, caloriesPer100g: 280, carbsPer100g: 2.2, proteinPer100g: 22.2, fatPer100g: 20.0, sodiumMgPer100g: 627, servingSizeGrams: 30, category: "Dairy"),
            FoodEntry(name: "Parmesan Cheese", brand: nil, caloriesPer100g: 431, carbsPer100g: 3.2, proteinPer100g: 38.5, fatPer100g: 29.0, sodiumMgPer100g: 1529, servingSizeGrams: 10, category: "Dairy"),
            FoodEntry(name: "Butter", brand: nil, caloriesPer100g: 717, carbsPer100g: 0.1, proteinPer100g: 0.9, fatPer100g: 81.0, sodiumMgPer100g: 576, servingSizeGrams: 14, category: "Dairy"),
            FoodEntry(name: "Cream Cheese", brand: nil, caloriesPer100g: 342, carbsPer100g: 4.1, proteinPer100g: 6.2, fatPer100g: 34.2, sodiumMgPer100g: 321, servingSizeGrams: 30, category: "Dairy"),
            FoodEntry(name: "Skyr", brand: nil, caloriesPer100g: 63, carbsPer100g: 3.7, proteinPer100g: 11.0, fatPer100g: 0.2, sodiumMgPer100g: 45, servingSizeGrams: 150, category: "Dairy"),
        ])

        // MARK: Snacks & Nuts
        foods.append(contentsOf: [
            FoodEntry(name: "Peanut Butter", brand: nil, caloriesPer100g: 588, carbsPer100g: 20.0, proteinPer100g: 25.0, fatPer100g: 50.0, sodiumMgPer100g: 459, servingSizeGrams: 32, category: "Snacks"),
            FoodEntry(name: "Almond Butter", brand: nil, caloriesPer100g: 614, carbsPer100g: 19.0, proteinPer100g: 21.0, fatPer100g: 56.0, sodiumMgPer100g: 7, servingSizeGrams: 32, category: "Snacks"),
            FoodEntry(name: "Almonds", brand: nil, caloriesPer100g: 579, carbsPer100g: 21.6, proteinPer100g: 21.2, fatPer100g: 49.9, sodiumMgPer100g: 1, servingSizeGrams: 28, category: "Snacks"),
            FoodEntry(name: "Walnuts", brand: nil, caloriesPer100g: 654, carbsPer100g: 13.7, proteinPer100g: 15.2, fatPer100g: 65.2, sodiumMgPer100g: 2, servingSizeGrams: 28, category: "Snacks"),
            FoodEntry(name: "Cashews", brand: nil, caloriesPer100g: 553, carbsPer100g: 30.2, proteinPer100g: 18.2, fatPer100g: 43.8, sodiumMgPer100g: 12, servingSizeGrams: 28, category: "Snacks"),
            FoodEntry(name: "Dark Chocolate (70%)", brand: nil, caloriesPer100g: 598, carbsPer100g: 45.9, proteinPer100g: 7.8, fatPer100g: 42.6, sodiumMgPer100g: 20, servingSizeGrams: 30, category: "Snacks"),
            FoodEntry(name: "Trail Mix", brand: nil, caloriesPer100g: 462, carbsPer100g: 44.0, proteinPer100g: 14.0, fatPer100g: 29.0, sodiumMgPer100g: 200, servingSizeGrams: 40, category: "Snacks"),
            FoodEntry(name: "Hummus", brand: nil, caloriesPer100g: 166, carbsPer100g: 14.3, proteinPer100g: 7.9, fatPer100g: 9.6, sodiumMgPer100g: 379, servingSizeGrams: 30, category: "Snacks"),
            FoodEntry(name: "Rice Cakes", brand: nil, caloriesPer100g: 387, carbsPer100g: 81.5, proteinPer100g: 8.0, fatPer100g: 2.8, sodiumMgPer100g: 29, servingSizeGrams: 9, category: "Snacks"),
            FoodEntry(name: "Pretzels", brand: nil, caloriesPer100g: 380, carbsPer100g: 79.8, proteinPer100g: 9.3, fatPer100g: 3.5, sodiumMgPer100g: 1357, servingSizeGrams: 30, category: "Snacks"),
            FoodEntry(name: "Dried Mango", brand: nil, caloriesPer100g: 319, carbsPer100g: 78.6, proteinPer100g: 2.4, fatPer100g: 0.9, sodiumMgPer100g: 100, servingSizeGrams: 40, category: "Snacks"),
            FoodEntry(name: "Honey", brand: nil, caloriesPer100g: 304, carbsPer100g: 82.4, proteinPer100g: 0.3, fatPer100g: 0.0, sodiumMgPer100g: 4, servingSizeGrams: 21, category: "Snacks"),
            FoodEntry(name: "Jam / Jelly", brand: nil, caloriesPer100g: 250, carbsPer100g: 62.0, proteinPer100g: 0.4, fatPer100g: 0.1, sodiumMgPer100g: 20, servingSizeGrams: 20, category: "Snacks"),
        ])

        // MARK: Beverages
        foods.append(contentsOf: [
            FoodEntry(name: "Orange Juice", brand: nil, caloriesPer100g: 45, carbsPer100g: 10.4, proteinPer100g: 0.7, fatPer100g: 0.2, sodiumMgPer100g: 1, servingSizeGrams: 250, category: "Beverages"),
            FoodEntry(name: "Apple Juice", brand: nil, caloriesPer100g: 46, carbsPer100g: 11.3, proteinPer100g: 0.1, fatPer100g: 0.1, sodiumMgPer100g: 4, servingSizeGrams: 250, category: "Beverages"),
            FoodEntry(name: "Coconut Water", brand: nil, caloriesPer100g: 19, carbsPer100g: 3.7, proteinPer100g: 0.7, fatPer100g: 0.2, sodiumMgPer100g: 105, servingSizeGrams: 330, category: "Beverages"),
            FoodEntry(name: "Oat Milk", brand: nil, caloriesPer100g: 48, carbsPer100g: 6.7, proteinPer100g: 1.0, fatPer100g: 1.5, sodiumMgPer100g: 39, servingSizeGrams: 250, category: "Beverages"),
            FoodEntry(name: "Almond Milk, Unsweetened", brand: nil, caloriesPer100g: 15, carbsPer100g: 0.3, proteinPer100g: 0.6, fatPer100g: 1.1, sodiumMgPer100g: 67, servingSizeGrams: 250, category: "Beverages"),
            FoodEntry(name: "Chocolate Milk", brand: nil, caloriesPer100g: 83, carbsPer100g: 10.4, proteinPer100g: 3.2, fatPer100g: 3.4, sodiumMgPer100g: 60, servingSizeGrams: 250, category: "Beverages"),
            FoodEntry(name: "Coffee, Black", brand: nil, caloriesPer100g: 2, carbsPer100g: 0.0, proteinPer100g: 0.3, fatPer100g: 0.0, sodiumMgPer100g: 5, servingSizeGrams: 240, category: "Beverages"),
            FoodEntry(name: "Sports Drink (Gatorade-type)", brand: nil, caloriesPer100g: 26, carbsPer100g: 6.4, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 41, servingSizeGrams: 355, category: "Beverages"),
            FoodEntry(name: "Protein Shake, Mixed", brand: nil, caloriesPer100g: 70, carbsPer100g: 5.0, proteinPer100g: 10.0, fatPer100g: 1.5, sodiumMgPer100g: 100, servingSizeGrams: 300, category: "Beverages"),
            FoodEntry(name: "Smoothie, Fruit", brand: nil, caloriesPer100g: 55, carbsPer100g: 12.0, proteinPer100g: 1.0, fatPer100g: 0.3, sodiumMgPer100g: 10, servingSizeGrams: 300, category: "Beverages"),
        ])

        // MARK: Sports Nutrition
        foods.append(contentsOf: [
            FoodEntry(name: "Energy Gel", brand: "Generic", caloriesPer100g: 250, carbsPer100g: 62.5, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 200, servingSizeGrams: 40, category: "Sports"),
            FoodEntry(name: "Energy Gel (Caffeinated)", brand: "Generic", caloriesPer100g: 250, carbsPer100g: 62.5, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 200, servingSizeGrams: 40, category: "Sports"),
            FoodEntry(name: "Energy Bar", brand: "Generic", caloriesPer100g: 350, carbsPer100g: 50.0, proteinPer100g: 10.0, fatPer100g: 12.0, sodiumMgPer100g: 200, servingSizeGrams: 55, category: "Sports"),
            FoodEntry(name: "Energy Chews", brand: "Generic", caloriesPer100g: 312, carbsPer100g: 78.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 156, servingSizeGrams: 50, category: "Sports"),
            FoodEntry(name: "Electrolyte Powder", brand: "Generic", caloriesPer100g: 100, carbsPer100g: 25.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 5000, servingSizeGrams: 10, category: "Sports"),
            FoodEntry(name: "Electrolyte Tablets", brand: "Generic", caloriesPer100g: 50, carbsPer100g: 12.5, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 7500, servingSizeGrams: 4, category: "Sports"),
            FoodEntry(name: "Maltodextrin Powder", brand: "Generic", caloriesPer100g: 380, carbsPer100g: 95.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 10, servingSizeGrams: 30, category: "Sports"),
            FoodEntry(name: "Isotonic Drink Mix", brand: "Generic", caloriesPer100g: 160, carbsPer100g: 40.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 2000, servingSizeGrams: 40, category: "Sports"),
            FoodEntry(name: "Recovery Drink Mix", brand: "Generic", caloriesPer100g: 300, carbsPer100g: 50.0, proteinPer100g: 15.0, fatPer100g: 3.0, sodiumMgPer100g: 300, servingSizeGrams: 50, category: "Sports"),
            FoodEntry(name: "Protein Bar", brand: "Generic", caloriesPer100g: 370, carbsPer100g: 30.0, proteinPer100g: 30.0, fatPer100g: 12.0, sodiumMgPer100g: 250, servingSizeGrams: 60, category: "Sports"),
            FoodEntry(name: "Clif Bar", brand: "Clif", caloriesPer100g: 365, carbsPer100g: 59.0, proteinPer100g: 14.7, fatPer100g: 8.8, sodiumMgPer100g: 382, servingSizeGrams: 68, category: "Sports"),
            FoodEntry(name: "Maurten Gel 100", brand: "Maurten", caloriesPer100g: 250, carbsPer100g: 62.5, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 200, servingSizeGrams: 40, category: "Sports"),
            FoodEntry(name: "Tailwind Endurance Fuel", brand: "Tailwind", caloriesPer100g: 340, carbsPer100g: 85.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 2600, servingSizeGrams: 27, category: "Sports"),
            FoodEntry(name: "SIS Go Gel", brand: "Science in Sport", caloriesPer100g: 136, carbsPer100g: 34.0, proteinPer100g: 0.0, fatPer100g: 0.1, sodiumMgPer100g: 18, servingSizeGrams: 60, category: "Sports"),
            FoodEntry(name: "Boiled Potato (salted)", brand: nil, caloriesPer100g: 87, carbsPer100g: 20.1, proteinPer100g: 1.9, fatPer100g: 0.1, sodiumMgPer100g: 240, servingSizeGrams: 150, category: "Sports"),
        ])

        // MARK: Oils & Fats
        foods.append(contentsOf: [
            FoodEntry(name: "Olive Oil", brand: nil, caloriesPer100g: 884, carbsPer100g: 0.0, proteinPer100g: 0.0, fatPer100g: 100.0, sodiumMgPer100g: 2, servingSizeGrams: 14, category: "Fats"),
            FoodEntry(name: "Coconut Oil", brand: nil, caloriesPer100g: 862, carbsPer100g: 0.0, proteinPer100g: 0.0, fatPer100g: 100.0, sodiumMgPer100g: 0, servingSizeGrams: 14, category: "Fats"),
        ])

        // MARK: Prepared Meals & Common Dishes
        foods.append(contentsOf: [
            FoodEntry(name: "Pizza, Margherita (1 slice)", brand: nil, caloriesPer100g: 266, carbsPer100g: 33.0, proteinPer100g: 11.4, fatPer100g: 10.4, sodiumMgPer100g: 598, servingSizeGrams: 107, category: "Meals"),
            FoodEntry(name: "Sushi, Salmon Nigiri", brand: nil, caloriesPer100g: 150, carbsPer100g: 22.0, proteinPer100g: 8.0, fatPer100g: 3.5, sodiumMgPer100g: 400, servingSizeGrams: 40, category: "Meals"),
            FoodEntry(name: "Burrito, Chicken", brand: nil, caloriesPer100g: 165, carbsPer100g: 17.0, proteinPer100g: 10.0, fatPer100g: 6.5, sodiumMgPer100g: 450, servingSizeGrams: 250, category: "Meals"),
            FoodEntry(name: "Soup, Chicken Noodle", brand: nil, caloriesPer100g: 31, carbsPer100g: 3.5, proteinPer100g: 1.9, fatPer100g: 1.1, sodiumMgPer100g: 343, servingSizeGrams: 250, category: "Meals"),
            FoodEntry(name: "Salad, Caesar with Chicken", brand: nil, caloriesPer100g: 127, carbsPer100g: 4.5, proteinPer100g: 10.0, fatPer100g: 8.0, sodiumMgPer100g: 360, servingSizeGrams: 200, category: "Meals"),
        ])

        return foods
    }()
    // swiftlint:enable function_body_length
}
