import Foundation

enum CommonFoodDatabase {
    struct FoodEntry: Sendable {
        let name: String
        let nameFr: String?
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

        let isFrench = Locale.current.language.languageCode?.identifier == "fr"

        let matches = allFoods.filter { food in
            let displayName = (isFrench ? food.nameFr : nil) ?? food.name
            return displayName.localizedCaseInsensitiveContains(trimmed)
                || food.name.localizedCaseInsensitiveContains(trimmed)
        }

        let sorted = matches.sorted { a, b in
            let aName = ((isFrench ? a.nameFr : nil) ?? a.name).lowercased()
            let bName = ((isFrench ? b.nameFr : nil) ?? b.name).lowercased()
            let aPrefix = aName.hasPrefix(trimmed)
            let bPrefix = bName.hasPrefix(trimmed)
            if aPrefix != bPrefix { return aPrefix }
            return aName < bName
        }

        return sorted.map { entry in
            let isFr = Locale.current.language.languageCode?.identifier == "fr"
            let displayName = (isFr ? entry.nameFr : nil) ?? entry.name
            return FoodSearchResult(
                id: "local_\(entry.name.lowercased().replacingOccurrences(of: " ", with: "_"))",
                name: displayName,
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
            FoodEntry(name: "Pasta, Cooked", nameFr: "Pâtes, cuites", brand: nil, caloriesPer100g: 131, carbsPer100g: 25.0, proteinPer100g: 5.0, fatPer100g: 1.1, sodiumMgPer100g: 1, servingSizeGrams: 200, category: "Grains"),
            FoodEntry(name: "Pasta, Dry", nameFr: "Pâtes, crues", brand: nil, caloriesPer100g: 371, carbsPer100g: 75.0, proteinPer100g: 13.0, fatPer100g: 1.5, sodiumMgPer100g: 6, servingSizeGrams: 80, category: "Grains"),
            FoodEntry(name: "White Rice, Cooked", nameFr: "Riz blanc, cuit", brand: nil, caloriesPer100g: 130, carbsPer100g: 28.2, proteinPer100g: 2.7, fatPer100g: 0.3, sodiumMgPer100g: 1, servingSizeGrams: 150, category: "Grains"),
            FoodEntry(name: "Brown Rice, Cooked", nameFr: "Riz complet, cuit", brand: nil, caloriesPer100g: 123, carbsPer100g: 25.6, proteinPer100g: 2.7, fatPer100g: 1.0, sodiumMgPer100g: 4, servingSizeGrams: 150, category: "Grains"),
            FoodEntry(name: "Oats, Dry", nameFr: "Flocons d'avoine", brand: nil, caloriesPer100g: 389, carbsPer100g: 66.3, proteinPer100g: 16.9, fatPer100g: 6.9, sodiumMgPer100g: 2, servingSizeGrams: 40, category: "Grains"),
            FoodEntry(name: "Oatmeal, Cooked", nameFr: "Porridge", brand: nil, caloriesPer100g: 68, carbsPer100g: 12.0, proteinPer100g: 2.4, fatPer100g: 1.4, sodiumMgPer100g: 49, servingSizeGrams: 240, category: "Grains"),
            FoodEntry(name: "Quinoa, Cooked", nameFr: "Quinoa, cuit", brand: nil, caloriesPer100g: 120, carbsPer100g: 21.3, proteinPer100g: 4.4, fatPer100g: 1.9, sodiumMgPer100g: 7, servingSizeGrams: 150, category: "Grains"),
            FoodEntry(name: "Couscous, Cooked", nameFr: "Couscous, cuit", brand: nil, caloriesPer100g: 112, carbsPer100g: 23.2, proteinPer100g: 3.8, fatPer100g: 0.2, sodiumMgPer100g: 5, servingSizeGrams: 150, category: "Grains"),
            FoodEntry(name: "Bread, White", nameFr: "Pain blanc", brand: nil, caloriesPer100g: 265, carbsPer100g: 49.0, proteinPer100g: 9.0, fatPer100g: 3.2, sodiumMgPer100g: 491, servingSizeGrams: 30, category: "Grains"),
            FoodEntry(name: "Bread, Whole Wheat", nameFr: "Pain complet", brand: nil, caloriesPer100g: 247, carbsPer100g: 41.3, proteinPer100g: 13.0, fatPer100g: 3.4, sodiumMgPer100g: 400, servingSizeGrams: 30, category: "Grains"),
            FoodEntry(name: "Bagel", nameFr: nil, brand: nil, caloriesPer100g: 257, carbsPer100g: 50.0, proteinPer100g: 10.0, fatPer100g: 1.6, sodiumMgPer100g: 450, servingSizeGrams: 100, category: "Grains"),
            FoodEntry(name: "Tortilla, Flour", nameFr: "Tortilla de blé", brand: nil, caloriesPer100g: 312, carbsPer100g: 51.6, proteinPer100g: 8.2, fatPer100g: 8.4, sodiumMgPer100g: 570, servingSizeGrams: 45, category: "Grains"),
            FoodEntry(name: "Granola", nameFr: nil, brand: nil, caloriesPer100g: 489, carbsPer100g: 64.0, proteinPer100g: 10.0, fatPer100g: 20.0, sodiumMgPer100g: 26, servingSizeGrams: 50, category: "Grains"),
            FoodEntry(name: "Cereal, Cornflakes", nameFr: "Céréales, cornflakes", brand: nil, caloriesPer100g: 357, carbsPer100g: 84.0, proteinPer100g: 7.5, fatPer100g: 0.4, sodiumMgPer100g: 729, servingSizeGrams: 30, category: "Grains"),
            FoodEntry(name: "Noodles, Egg, Cooked", nameFr: "Nouilles aux œufs, cuites", brand: nil, caloriesPer100g: 138, carbsPer100g: 25.2, proteinPer100g: 4.5, fatPer100g: 2.1, sodiumMgPer100g: 5, servingSizeGrams: 200, category: "Grains"),
            FoodEntry(name: "Pancake", nameFr: "Crêpe", brand: nil, caloriesPer100g: 227, carbsPer100g: 28.0, proteinPer100g: 6.4, fatPer100g: 10.0, sodiumMgPer100g: 439, servingSizeGrams: 75, category: "Grains"),
            FoodEntry(name: "Muesli", nameFr: nil, brand: nil, caloriesPer100g: 340, carbsPer100g: 56.0, proteinPer100g: 10.0, fatPer100g: 8.0, sodiumMgPer100g: 10, servingSizeGrams: 50, category: "Grains"),
            FoodEntry(name: "Polenta, Cooked", nameFr: "Polenta, cuite", brand: nil, caloriesPer100g: 70, carbsPer100g: 15.0, proteinPer100g: 1.6, fatPer100g: 0.3, sodiumMgPer100g: 2, servingSizeGrams: 200, category: "Grains"),
        ])

        // MARK: Proteins
        foods.append(contentsOf: [
            FoodEntry(name: "Chicken Breast, Cooked", nameFr: "Blanc de poulet, cuit", brand: nil, caloriesPer100g: 165, carbsPer100g: 0.0, proteinPer100g: 31.0, fatPer100g: 3.6, sodiumMgPer100g: 74, servingSizeGrams: 120, category: "Proteins"),
            FoodEntry(name: "Beef, Lean, Cooked", nameFr: "Bœuf maigre, cuit", brand: nil, caloriesPer100g: 250, carbsPer100g: 0.0, proteinPer100g: 26.0, fatPer100g: 15.0, sodiumMgPer100g: 72, servingSizeGrams: 120, category: "Proteins"),
            FoodEntry(name: "Salmon, Cooked", nameFr: "Saumon, cuit", brand: nil, caloriesPer100g: 208, carbsPer100g: 0.0, proteinPer100g: 20.0, fatPer100g: 13.0, sodiumMgPer100g: 59, servingSizeGrams: 125, category: "Proteins"),
            FoodEntry(name: "Tuna, Canned in Water", nameFr: "Thon en conserve", brand: nil, caloriesPer100g: 116, carbsPer100g: 0.0, proteinPer100g: 25.5, fatPer100g: 0.8, sodiumMgPer100g: 338, servingSizeGrams: 85, category: "Proteins"),
            FoodEntry(name: "Eggs, Whole", nameFr: "Œufs entiers", brand: nil, caloriesPer100g: 155, carbsPer100g: 1.1, proteinPer100g: 13.0, fatPer100g: 11.0, sodiumMgPer100g: 124, servingSizeGrams: 50, category: "Proteins"),
            FoodEntry(name: "Egg White", nameFr: "Blanc d'œuf", brand: nil, caloriesPer100g: 52, carbsPer100g: 0.7, proteinPer100g: 11.0, fatPer100g: 0.2, sodiumMgPer100g: 166, servingSizeGrams: 33, category: "Proteins"),
            FoodEntry(name: "Tofu, Firm", nameFr: "Tofu ferme", brand: nil, caloriesPer100g: 144, carbsPer100g: 3.0, proteinPer100g: 15.6, fatPer100g: 8.7, sodiumMgPer100g: 14, servingSizeGrams: 100, category: "Proteins"),
            FoodEntry(name: "Turkey Breast, Cooked", nameFr: "Blanc de dinde, cuit", brand: nil, caloriesPer100g: 135, carbsPer100g: 0.0, proteinPer100g: 30.0, fatPer100g: 1.0, sodiumMgPer100g: 53, servingSizeGrams: 120, category: "Proteins"),
            FoodEntry(name: "Pork Loin, Cooked", nameFr: "Filet de porc, cuit", brand: nil, caloriesPer100g: 242, carbsPer100g: 0.0, proteinPer100g: 27.3, fatPer100g: 14.0, sodiumMgPer100g: 51, servingSizeGrams: 120, category: "Proteins"),
            FoodEntry(name: "Lentils, Cooked", nameFr: "Lentilles, cuites", brand: nil, caloriesPer100g: 116, carbsPer100g: 20.0, proteinPer100g: 9.0, fatPer100g: 0.4, sodiumMgPer100g: 2, servingSizeGrams: 150, category: "Proteins"),
            FoodEntry(name: "Chickpeas, Cooked", nameFr: "Pois chiches, cuits", brand: nil, caloriesPer100g: 164, carbsPer100g: 27.4, proteinPer100g: 8.9, fatPer100g: 2.6, sodiumMgPer100g: 7, servingSizeGrams: 150, category: "Proteins"),
            FoodEntry(name: "Black Beans, Cooked", nameFr: "Haricots noirs, cuits", brand: nil, caloriesPer100g: 132, carbsPer100g: 23.7, proteinPer100g: 8.9, fatPer100g: 0.5, sodiumMgPer100g: 1, servingSizeGrams: 150, category: "Proteins"),
            FoodEntry(name: "Shrimp, Cooked", nameFr: "Crevettes, cuites", brand: nil, caloriesPer100g: 99, carbsPer100g: 0.2, proteinPer100g: 24.0, fatPer100g: 0.3, sodiumMgPer100g: 111, servingSizeGrams: 85, category: "Proteins"),
            FoodEntry(name: "Cod, Cooked", nameFr: "Cabillaud, cuit", brand: nil, caloriesPer100g: 105, carbsPer100g: 0.0, proteinPer100g: 23.0, fatPer100g: 0.9, sodiumMgPer100g: 78, servingSizeGrams: 125, category: "Proteins"),
            FoodEntry(name: "Ham, Lean", nameFr: "Jambon maigre", brand: nil, caloriesPer100g: 145, carbsPer100g: 1.5, proteinPer100g: 21.0, fatPer100g: 5.5, sodiumMgPer100g: 1203, servingSizeGrams: 60, category: "Proteins"),
            FoodEntry(name: "Whey Protein Powder", nameFr: "Protéine whey en poudre", brand: nil, caloriesPer100g: 400, carbsPer100g: 10.0, proteinPer100g: 75.0, fatPer100g: 5.0, sodiumMgPer100g: 200, servingSizeGrams: 30, category: "Proteins"),
        ])

        // MARK: Fruits
        foods.append(contentsOf: [
            FoodEntry(name: "Banana", nameFr: "Banane", brand: nil, caloriesPer100g: 89, carbsPer100g: 22.8, proteinPer100g: 1.1, fatPer100g: 0.3, sodiumMgPer100g: 1, servingSizeGrams: 120, category: "Fruits"),
            FoodEntry(name: "Apple", nameFr: "Pomme", brand: nil, caloriesPer100g: 52, carbsPer100g: 13.8, proteinPer100g: 0.3, fatPer100g: 0.2, sodiumMgPer100g: 1, servingSizeGrams: 180, category: "Fruits"),
            FoodEntry(name: "Orange", nameFr: nil, brand: nil, caloriesPer100g: 47, carbsPer100g: 11.8, proteinPer100g: 0.9, fatPer100g: 0.1, sodiumMgPer100g: 0, servingSizeGrams: 130, category: "Fruits"),
            FoodEntry(name: "Strawberries", nameFr: "Fraises", brand: nil, caloriesPer100g: 32, carbsPer100g: 7.7, proteinPer100g: 0.7, fatPer100g: 0.3, sodiumMgPer100g: 1, servingSizeGrams: 150, category: "Fruits"),
            FoodEntry(name: "Blueberries", nameFr: "Myrtilles", brand: nil, caloriesPer100g: 57, carbsPer100g: 14.5, proteinPer100g: 0.7, fatPer100g: 0.3, sodiumMgPer100g: 1, servingSizeGrams: 150, category: "Fruits"),
            FoodEntry(name: "Mango", nameFr: "Mangue", brand: nil, caloriesPer100g: 60, carbsPer100g: 15.0, proteinPer100g: 0.8, fatPer100g: 0.4, sodiumMgPer100g: 1, servingSizeGrams: 165, category: "Fruits"),
            FoodEntry(name: "Grapes", nameFr: "Raisin", brand: nil, caloriesPer100g: 69, carbsPer100g: 18.1, proteinPer100g: 0.7, fatPer100g: 0.2, sodiumMgPer100g: 2, servingSizeGrams: 150, category: "Fruits"),
            FoodEntry(name: "Watermelon", nameFr: "Pastèque", brand: nil, caloriesPer100g: 30, carbsPer100g: 7.6, proteinPer100g: 0.6, fatPer100g: 0.2, sodiumMgPer100g: 1, servingSizeGrams: 200, category: "Fruits"),
            FoodEntry(name: "Avocado", nameFr: "Avocat", brand: nil, caloriesPer100g: 160, carbsPer100g: 8.5, proteinPer100g: 2.0, fatPer100g: 14.7, sodiumMgPer100g: 7, servingSizeGrams: 70, category: "Fruits"),
            FoodEntry(name: "Dates, Medjool", nameFr: "Dattes Medjool", brand: nil, caloriesPer100g: 277, carbsPer100g: 75.0, proteinPer100g: 1.8, fatPer100g: 0.2, sodiumMgPer100g: 1, servingSizeGrams: 24, category: "Fruits"),
            FoodEntry(name: "Pineapple", nameFr: "Ananas", brand: nil, caloriesPer100g: 50, carbsPer100g: 13.1, proteinPer100g: 0.5, fatPer100g: 0.1, sodiumMgPer100g: 1, servingSizeGrams: 165, category: "Fruits"),
            FoodEntry(name: "Kiwi", nameFr: nil, brand: nil, caloriesPer100g: 61, carbsPer100g: 14.7, proteinPer100g: 1.1, fatPer100g: 0.5, sodiumMgPer100g: 3, servingSizeGrams: 75, category: "Fruits"),
            FoodEntry(name: "Peach", nameFr: "Pêche", brand: nil, caloriesPer100g: 39, carbsPer100g: 9.5, proteinPer100g: 0.9, fatPer100g: 0.3, sodiumMgPer100g: 0, servingSizeGrams: 150, category: "Fruits"),
            FoodEntry(name: "Dried Apricots", nameFr: "Abricots secs", brand: nil, caloriesPer100g: 241, carbsPer100g: 62.6, proteinPer100g: 3.4, fatPer100g: 0.5, sodiumMgPer100g: 10, servingSizeGrams: 30, category: "Fruits"),
            FoodEntry(name: "Raisins", nameFr: "Raisins secs", brand: nil, caloriesPer100g: 299, carbsPer100g: 79.2, proteinPer100g: 3.1, fatPer100g: 0.5, sodiumMgPer100g: 11, servingSizeGrams: 40, category: "Fruits"),
        ])

        // MARK: Vegetables
        foods.append(contentsOf: [
            FoodEntry(name: "Potato, Boiled", nameFr: "Pomme de terre, bouillie", brand: nil, caloriesPer100g: 87, carbsPer100g: 20.1, proteinPer100g: 1.9, fatPer100g: 0.1, sodiumMgPer100g: 5, servingSizeGrams: 150, category: "Vegetables"),
            FoodEntry(name: "Sweet Potato, Baked", nameFr: "Patate douce, cuite", brand: nil, caloriesPer100g: 90, carbsPer100g: 20.7, proteinPer100g: 2.0, fatPer100g: 0.1, sodiumMgPer100g: 36, servingSizeGrams: 150, category: "Vegetables"),
            FoodEntry(name: "Broccoli, Cooked", nameFr: "Brocoli, cuit", brand: nil, caloriesPer100g: 35, carbsPer100g: 7.2, proteinPer100g: 2.4, fatPer100g: 0.4, sodiumMgPer100g: 41, servingSizeGrams: 90, category: "Vegetables"),
            FoodEntry(name: "Spinach, Raw", nameFr: "Épinards, crus", brand: nil, caloriesPer100g: 23, carbsPer100g: 3.6, proteinPer100g: 2.9, fatPer100g: 0.4, sodiumMgPer100g: 79, servingSizeGrams: 30, category: "Vegetables"),
            FoodEntry(name: "Carrots, Raw", nameFr: "Carottes, crues", brand: nil, caloriesPer100g: 41, carbsPer100g: 9.6, proteinPer100g: 0.9, fatPer100g: 0.2, sodiumMgPer100g: 69, servingSizeGrams: 80, category: "Vegetables"),
            FoodEntry(name: "Tomato", nameFr: "Tomate", brand: nil, caloriesPer100g: 18, carbsPer100g: 3.9, proteinPer100g: 0.9, fatPer100g: 0.2, sodiumMgPer100g: 5, servingSizeGrams: 120, category: "Vegetables"),
            FoodEntry(name: "Mushrooms", nameFr: "Champignons", brand: nil, caloriesPer100g: 22, carbsPer100g: 3.3, proteinPer100g: 3.1, fatPer100g: 0.3, sodiumMgPer100g: 5, servingSizeGrams: 70, category: "Vegetables"),
            FoodEntry(name: "Corn, Cooked", nameFr: "Maïs, cuit", brand: nil, caloriesPer100g: 96, carbsPer100g: 21.0, proteinPer100g: 3.4, fatPer100g: 1.5, sodiumMgPer100g: 1, servingSizeGrams: 150, category: "Vegetables"),
            FoodEntry(name: "Green Peas, Cooked", nameFr: "Petits pois, cuits", brand: nil, caloriesPer100g: 84, carbsPer100g: 15.6, proteinPer100g: 5.4, fatPer100g: 0.2, sodiumMgPer100g: 3, servingSizeGrams: 80, category: "Vegetables"),
            FoodEntry(name: "Zucchini, Cooked", nameFr: "Courgette, cuite", brand: nil, caloriesPer100g: 17, carbsPer100g: 3.1, proteinPer100g: 1.2, fatPer100g: 0.3, sodiumMgPer100g: 3, servingSizeGrams: 120, category: "Vegetables"),
            FoodEntry(name: "Bell Pepper, Red", nameFr: "Poivron rouge", brand: nil, caloriesPer100g: 31, carbsPer100g: 6.0, proteinPer100g: 1.0, fatPer100g: 0.3, sodiumMgPer100g: 4, servingSizeGrams: 120, category: "Vegetables"),
            FoodEntry(name: "Cucumber", nameFr: "Concombre", brand: nil, caloriesPer100g: 15, carbsPer100g: 3.6, proteinPer100g: 0.7, fatPer100g: 0.1, sodiumMgPer100g: 2, servingSizeGrams: 100, category: "Vegetables"),
            FoodEntry(name: "Lettuce, Mixed Greens", nameFr: "Salade verte", brand: nil, caloriesPer100g: 15, carbsPer100g: 2.9, proteinPer100g: 1.3, fatPer100g: 0.2, sodiumMgPer100g: 28, servingSizeGrams: 50, category: "Vegetables"),
            FoodEntry(name: "Cauliflower, Cooked", nameFr: "Chou-fleur, cuit", brand: nil, caloriesPer100g: 23, carbsPer100g: 4.1, proteinPer100g: 1.8, fatPer100g: 0.5, sodiumMgPer100g: 15, servingSizeGrams: 100, category: "Vegetables"),
            FoodEntry(name: "Onion", nameFr: "Oignon", brand: nil, caloriesPer100g: 40, carbsPer100g: 9.3, proteinPer100g: 1.1, fatPer100g: 0.1, sodiumMgPer100g: 4, servingSizeGrams: 110, category: "Vegetables"),
        ])

        // MARK: Dairy
        foods.append(contentsOf: [
            FoodEntry(name: "Milk, Whole", nameFr: "Lait entier", brand: nil, caloriesPer100g: 61, carbsPer100g: 4.8, proteinPer100g: 3.2, fatPer100g: 3.3, sodiumMgPer100g: 43, servingSizeGrams: 250, category: "Dairy"),
            FoodEntry(name: "Milk, Semi-Skimmed", nameFr: "Lait demi-écrémé", brand: nil, caloriesPer100g: 46, carbsPer100g: 4.7, proteinPer100g: 3.4, fatPer100g: 1.5, sodiumMgPer100g: 44, servingSizeGrams: 250, category: "Dairy"),
            FoodEntry(name: "Yogurt, Plain", nameFr: "Yaourt nature", brand: nil, caloriesPer100g: 61, carbsPer100g: 4.7, proteinPer100g: 3.5, fatPer100g: 3.3, sodiumMgPer100g: 46, servingSizeGrams: 125, category: "Dairy"),
            FoodEntry(name: "Greek Yogurt, Plain", nameFr: "Yaourt grec nature", brand: nil, caloriesPer100g: 97, carbsPer100g: 3.6, proteinPer100g: 9.0, fatPer100g: 5.0, sodiumMgPer100g: 47, servingSizeGrams: 170, category: "Dairy"),
            FoodEntry(name: "Greek Yogurt, 0% Fat", nameFr: "Yaourt grec 0%", brand: nil, caloriesPer100g: 59, carbsPer100g: 3.6, proteinPer100g: 10.0, fatPer100g: 0.4, sodiumMgPer100g: 47, servingSizeGrams: 170, category: "Dairy"),
            FoodEntry(name: "Cottage Cheese", nameFr: "Fromage blanc", brand: nil, caloriesPer100g: 98, carbsPer100g: 3.4, proteinPer100g: 11.1, fatPer100g: 4.3, sodiumMgPer100g: 364, servingSizeGrams: 110, category: "Dairy"),
            FoodEntry(name: "Cheddar Cheese", nameFr: "Cheddar", brand: nil, caloriesPer100g: 403, carbsPer100g: 1.3, proteinPer100g: 25.0, fatPer100g: 33.1, sodiumMgPer100g: 621, servingSizeGrams: 30, category: "Dairy"),
            FoodEntry(name: "Mozzarella Cheese", nameFr: "Mozzarella", brand: nil, caloriesPer100g: 280, carbsPer100g: 2.2, proteinPer100g: 22.2, fatPer100g: 20.0, sodiumMgPer100g: 627, servingSizeGrams: 30, category: "Dairy"),
            FoodEntry(name: "Parmesan Cheese", nameFr: "Parmesan", brand: nil, caloriesPer100g: 431, carbsPer100g: 3.2, proteinPer100g: 38.5, fatPer100g: 29.0, sodiumMgPer100g: 1529, servingSizeGrams: 10, category: "Dairy"),
            FoodEntry(name: "Butter", nameFr: "Beurre", brand: nil, caloriesPer100g: 717, carbsPer100g: 0.1, proteinPer100g: 0.9, fatPer100g: 81.0, sodiumMgPer100g: 576, servingSizeGrams: 14, category: "Dairy"),
            FoodEntry(name: "Cream Cheese", nameFr: "Fromage frais", brand: nil, caloriesPer100g: 342, carbsPer100g: 4.1, proteinPer100g: 6.2, fatPer100g: 34.2, sodiumMgPer100g: 321, servingSizeGrams: 30, category: "Dairy"),
            FoodEntry(name: "Skyr", nameFr: nil, brand: nil, caloriesPer100g: 63, carbsPer100g: 3.7, proteinPer100g: 11.0, fatPer100g: 0.2, sodiumMgPer100g: 45, servingSizeGrams: 150, category: "Dairy"),
        ])

        // MARK: Snacks & Nuts
        foods.append(contentsOf: [
            FoodEntry(name: "Peanut Butter", nameFr: "Beurre de cacahuète", brand: nil, caloriesPer100g: 588, carbsPer100g: 20.0, proteinPer100g: 25.0, fatPer100g: 50.0, sodiumMgPer100g: 459, servingSizeGrams: 32, category: "Snacks"),
            FoodEntry(name: "Almond Butter", nameFr: "Purée d'amande", brand: nil, caloriesPer100g: 614, carbsPer100g: 19.0, proteinPer100g: 21.0, fatPer100g: 56.0, sodiumMgPer100g: 7, servingSizeGrams: 32, category: "Snacks"),
            FoodEntry(name: "Almonds", nameFr: "Amandes", brand: nil, caloriesPer100g: 579, carbsPer100g: 21.6, proteinPer100g: 21.2, fatPer100g: 49.9, sodiumMgPer100g: 1, servingSizeGrams: 28, category: "Snacks"),
            FoodEntry(name: "Walnuts", nameFr: "Noix", brand: nil, caloriesPer100g: 654, carbsPer100g: 13.7, proteinPer100g: 15.2, fatPer100g: 65.2, sodiumMgPer100g: 2, servingSizeGrams: 28, category: "Snacks"),
            FoodEntry(name: "Cashews", nameFr: "Noix de cajou", brand: nil, caloriesPer100g: 553, carbsPer100g: 30.2, proteinPer100g: 18.2, fatPer100g: 43.8, sodiumMgPer100g: 12, servingSizeGrams: 28, category: "Snacks"),
            FoodEntry(name: "Dark Chocolate (70%)", nameFr: "Chocolat noir (70%)", brand: nil, caloriesPer100g: 598, carbsPer100g: 45.9, proteinPer100g: 7.8, fatPer100g: 42.6, sodiumMgPer100g: 20, servingSizeGrams: 30, category: "Snacks"),
            FoodEntry(name: "Trail Mix", nameFr: "Mélange de fruits secs", brand: nil, caloriesPer100g: 462, carbsPer100g: 44.0, proteinPer100g: 14.0, fatPer100g: 29.0, sodiumMgPer100g: 200, servingSizeGrams: 40, category: "Snacks"),
            FoodEntry(name: "Hummus", nameFr: "Houmous", brand: nil, caloriesPer100g: 166, carbsPer100g: 14.3, proteinPer100g: 7.9, fatPer100g: 9.6, sodiumMgPer100g: 379, servingSizeGrams: 30, category: "Snacks"),
            FoodEntry(name: "Rice Cakes", nameFr: "Galettes de riz", brand: nil, caloriesPer100g: 387, carbsPer100g: 81.5, proteinPer100g: 8.0, fatPer100g: 2.8, sodiumMgPer100g: 29, servingSizeGrams: 9, category: "Snacks"),
            FoodEntry(name: "Pretzels", nameFr: "Bretzels", brand: nil, caloriesPer100g: 380, carbsPer100g: 79.8, proteinPer100g: 9.3, fatPer100g: 3.5, sodiumMgPer100g: 1357, servingSizeGrams: 30, category: "Snacks"),
            FoodEntry(name: "Dried Mango", nameFr: "Mangue séchée", brand: nil, caloriesPer100g: 319, carbsPer100g: 78.6, proteinPer100g: 2.4, fatPer100g: 0.9, sodiumMgPer100g: 100, servingSizeGrams: 40, category: "Snacks"),
            FoodEntry(name: "Honey", nameFr: "Miel", brand: nil, caloriesPer100g: 304, carbsPer100g: 82.4, proteinPer100g: 0.3, fatPer100g: 0.0, sodiumMgPer100g: 4, servingSizeGrams: 21, category: "Snacks"),
            FoodEntry(name: "Jam / Jelly", nameFr: "Confiture", brand: nil, caloriesPer100g: 250, carbsPer100g: 62.0, proteinPer100g: 0.4, fatPer100g: 0.1, sodiumMgPer100g: 20, servingSizeGrams: 20, category: "Snacks"),
        ])

        // MARK: Beverages
        foods.append(contentsOf: [
            FoodEntry(name: "Orange Juice", nameFr: "Jus d'orange", brand: nil, caloriesPer100g: 45, carbsPer100g: 10.4, proteinPer100g: 0.7, fatPer100g: 0.2, sodiumMgPer100g: 1, servingSizeGrams: 250, category: "Beverages"),
            FoodEntry(name: "Apple Juice", nameFr: "Jus de pomme", brand: nil, caloriesPer100g: 46, carbsPer100g: 11.3, proteinPer100g: 0.1, fatPer100g: 0.1, sodiumMgPer100g: 4, servingSizeGrams: 250, category: "Beverages"),
            FoodEntry(name: "Coconut Water", nameFr: "Eau de coco", brand: nil, caloriesPer100g: 19, carbsPer100g: 3.7, proteinPer100g: 0.7, fatPer100g: 0.2, sodiumMgPer100g: 105, servingSizeGrams: 330, category: "Beverages"),
            FoodEntry(name: "Oat Milk", nameFr: "Lait d'avoine", brand: nil, caloriesPer100g: 48, carbsPer100g: 6.7, proteinPer100g: 1.0, fatPer100g: 1.5, sodiumMgPer100g: 39, servingSizeGrams: 250, category: "Beverages"),
            FoodEntry(name: "Almond Milk, Unsweetened", nameFr: "Lait d'amande non sucré", brand: nil, caloriesPer100g: 15, carbsPer100g: 0.3, proteinPer100g: 0.6, fatPer100g: 1.1, sodiumMgPer100g: 67, servingSizeGrams: 250, category: "Beverages"),
            FoodEntry(name: "Chocolate Milk", nameFr: "Lait chocolaté", brand: nil, caloriesPer100g: 83, carbsPer100g: 10.4, proteinPer100g: 3.2, fatPer100g: 3.4, sodiumMgPer100g: 60, servingSizeGrams: 250, category: "Beverages"),
            FoodEntry(name: "Coffee, Black", nameFr: "Café noir", brand: nil, caloriesPer100g: 2, carbsPer100g: 0.0, proteinPer100g: 0.3, fatPer100g: 0.0, sodiumMgPer100g: 5, servingSizeGrams: 240, category: "Beverages"),
            FoodEntry(name: "Sports Drink (Gatorade-type)", nameFr: "Boisson sportive", brand: nil, caloriesPer100g: 26, carbsPer100g: 6.4, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 41, servingSizeGrams: 355, category: "Beverages"),
            FoodEntry(name: "Protein Shake, Mixed", nameFr: "Shake protéiné", brand: nil, caloriesPer100g: 70, carbsPer100g: 5.0, proteinPer100g: 10.0, fatPer100g: 1.5, sodiumMgPer100g: 100, servingSizeGrams: 300, category: "Beverages"),
            FoodEntry(name: "Smoothie, Fruit", nameFr: "Smoothie aux fruits", brand: nil, caloriesPer100g: 55, carbsPer100g: 12.0, proteinPer100g: 1.0, fatPer100g: 0.3, sodiumMgPer100g: 10, servingSizeGrams: 300, category: "Beverages"),
        ])

        // MARK: Sports Nutrition (see CommonFoodDatabase+SportsNutrition.swift)
        foods.append(contentsOf: Self.sportsNutritionProducts)

        // MARK: Oils & Fats
        foods.append(contentsOf: [
            FoodEntry(name: "Olive Oil", nameFr: "Huile d'olive", brand: nil, caloriesPer100g: 884, carbsPer100g: 0.0, proteinPer100g: 0.0, fatPer100g: 100.0, sodiumMgPer100g: 2, servingSizeGrams: 14, category: "Fats"),
            FoodEntry(name: "Coconut Oil", nameFr: "Huile de coco", brand: nil, caloriesPer100g: 862, carbsPer100g: 0.0, proteinPer100g: 0.0, fatPer100g: 100.0, sodiumMgPer100g: 0, servingSizeGrams: 14, category: "Fats"),
        ])

        // MARK: Prepared Meals & Common Dishes
        foods.append(contentsOf: [
            FoodEntry(name: "Pizza, Margherita (1 slice)", nameFr: "Pizza Margherita (1 part)", brand: nil, caloriesPer100g: 266, carbsPer100g: 33.0, proteinPer100g: 11.4, fatPer100g: 10.4, sodiumMgPer100g: 598, servingSizeGrams: 107, category: "Meals"),
            FoodEntry(name: "Sushi, Salmon Nigiri", nameFr: "Sushi saumon nigiri", brand: nil, caloriesPer100g: 150, carbsPer100g: 22.0, proteinPer100g: 8.0, fatPer100g: 3.5, sodiumMgPer100g: 400, servingSizeGrams: 40, category: "Meals"),
            FoodEntry(name: "Burrito, Chicken", nameFr: "Burrito au poulet", brand: nil, caloriesPer100g: 165, carbsPer100g: 17.0, proteinPer100g: 10.0, fatPer100g: 6.5, sodiumMgPer100g: 450, servingSizeGrams: 250, category: "Meals"),
            FoodEntry(name: "Soup, Chicken Noodle", nameFr: "Soupe de nouilles au poulet", brand: nil, caloriesPer100g: 31, carbsPer100g: 3.5, proteinPer100g: 1.9, fatPer100g: 1.1, sodiumMgPer100g: 343, servingSizeGrams: 250, category: "Meals"),
            FoodEntry(name: "Salad, Caesar with Chicken", nameFr: "Salade César au poulet", brand: nil, caloriesPer100g: 127, carbsPer100g: 4.5, proteinPer100g: 10.0, fatPer100g: 8.0, sodiumMgPer100g: 360, servingSizeGrams: 200, category: "Meals"),
        ])

        // MARK: Bakery & Pastries
        foods.append(contentsOf: [
            FoodEntry(name: "Baguette", nameFr: nil, brand: nil, caloriesPer100g: 270, carbsPer100g: 56.0, proteinPer100g: 9.0, fatPer100g: 1.0, sodiumMgPer100g: 600, servingSizeGrams: 60, category: "Bakery"),
            FoodEntry(name: "Croissant", nameFr: nil, brand: nil, caloriesPer100g: 406, carbsPer100g: 45.5, proteinPer100g: 8.2, fatPer100g: 21.0, sodiumMgPer100g: 330, servingSizeGrams: 60, category: "Bakery"),
            FoodEntry(name: "Pain au chocolat", nameFr: nil, brand: nil, caloriesPer100g: 414, carbsPer100g: 45.0, proteinPer100g: 7.5, fatPer100g: 22.0, sodiumMgPer100g: 310, servingSizeGrams: 70, category: "Bakery"),
            FoodEntry(name: "Brioche", nameFr: nil, brand: nil, caloriesPer100g: 357, carbsPer100g: 48.0, proteinPer100g: 8.5, fatPer100g: 14.0, sodiumMgPer100g: 350, servingSizeGrams: 50, category: "Bakery"),
            FoodEntry(name: "Pain complet", nameFr: nil, brand: nil, caloriesPer100g: 247, carbsPer100g: 41.0, proteinPer100g: 13.0, fatPer100g: 3.4, sodiumMgPer100g: 400, servingSizeGrams: 30, category: "Bakery"),
            FoodEntry(name: "Pain de mie", nameFr: nil, brand: nil, caloriesPer100g: 275, carbsPer100g: 49.0, proteinPer100g: 8.0, fatPer100g: 4.5, sodiumMgPer100g: 500, servingSizeGrams: 30, category: "Bakery"),
            FoodEntry(name: "Muffin, Blueberry", nameFr: "Muffin aux myrtilles", brand: nil, caloriesPer100g: 350, carbsPer100g: 48.0, proteinPer100g: 5.5, fatPer100g: 15.0, sodiumMgPer100g: 320, servingSizeGrams: 115, category: "Bakery"),
            FoodEntry(name: "Cookie, Chocolate Chip", nameFr: "Cookie aux pépites de chocolat", brand: nil, caloriesPer100g: 488, carbsPer100g: 63.0, proteinPer100g: 5.0, fatPer100g: 24.0, sodiumMgPer100g: 350, servingSizeGrams: 30, category: "Bakery"),
            FoodEntry(name: "Crêpe", nameFr: nil, brand: nil, caloriesPer100g: 190, carbsPer100g: 28.0, proteinPer100g: 6.0, fatPer100g: 6.0, sodiumMgPer100g: 150, servingSizeGrams: 60, category: "Bakery"),
            FoodEntry(name: "Gaufre", nameFr: nil, brand: nil, caloriesPer100g: 290, carbsPer100g: 39.0, proteinPer100g: 6.0, fatPer100g: 12.0, sodiumMgPer100g: 350, servingSizeGrams: 75, category: "Bakery"),
        ])

        // MARK: Snacks & Confectionery (additional)
        foods.append(contentsOf: [
            FoodEntry(name: "Oreo", nameFr: nil, brand: "Oreo", caloriesPer100g: 480, carbsPer100g: 67.0, proteinPer100g: 4.5, fatPer100g: 21.0, sodiumMgPer100g: 400, servingSizeGrams: 11, category: "Snacks"),
            FoodEntry(name: "Petit Beurre", nameFr: nil, brand: "LU", caloriesPer100g: 435, carbsPer100g: 75.0, proteinPer100g: 7.0, fatPer100g: 12.0, sodiumMgPer100g: 400, servingSizeGrams: 8, category: "Snacks"),
            FoodEntry(name: "Nutella", nameFr: nil, brand: "Ferrero", caloriesPer100g: 539, carbsPer100g: 57.5, proteinPer100g: 6.3, fatPer100g: 30.9, sodiumMgPer100g: 41, servingSizeGrams: 15, category: "Snacks"),
            FoodEntry(name: "Snickers", nameFr: nil, brand: "Mars", caloriesPer100g: 488, carbsPer100g: 60.0, proteinPer100g: 7.6, fatPer100g: 23.5, sodiumMgPer100g: 230, servingSizeGrams: 52, category: "Snacks"),
            FoodEntry(name: "Peanut M&M's", nameFr: nil, brand: "Mars", caloriesPer100g: 506, carbsPer100g: 57.0, proteinPer100g: 9.5, fatPer100g: 25.0, sodiumMgPer100g: 50, servingSizeGrams: 45, category: "Snacks"),
            FoodEntry(name: "Haribo Goldbears", nameFr: "Haribo Ours d'or", brand: "Haribo", caloriesPer100g: 343, carbsPer100g: 77.0, proteinPer100g: 6.9, fatPer100g: 0.5, sodiumMgPer100g: 15, servingSizeGrams: 20, category: "Snacks"),
            FoodEntry(name: "Madeleines", nameFr: nil, brand: nil, caloriesPer100g: 417, carbsPer100g: 52.0, proteinPer100g: 6.0, fatPer100g: 20.0, sodiumMgPer100g: 300, servingSizeGrams: 25, category: "Snacks"),
            FoodEntry(name: "Speculoos", nameFr: nil, brand: nil, caloriesPer100g: 480, carbsPer100g: 68.0, proteinPer100g: 5.0, fatPer100g: 21.0, sodiumMgPer100g: 400, servingSizeGrams: 8, category: "Snacks"),
            FoodEntry(name: "Compote, Apple", nameFr: "Compote de pommes", brand: nil, caloriesPer100g: 65, carbsPer100g: 15.0, proteinPer100g: 0.3, fatPer100g: 0.2, sodiumMgPer100g: 5, servingSizeGrams: 100, category: "Snacks"),
            FoodEntry(name: "Dried Figs", nameFr: "Figues séchées", brand: nil, caloriesPer100g: 249, carbsPer100g: 63.9, proteinPer100g: 3.3, fatPer100g: 0.9, sodiumMgPer100g: 10, servingSizeGrams: 30, category: "Snacks"),
            FoodEntry(name: "Granola Bar", nameFr: "Barre de céréales", brand: nil, caloriesPer100g: 420, carbsPer100g: 63.0, proteinPer100g: 7.0, fatPer100g: 16.0, sodiumMgPer100g: 200, servingSizeGrams: 35, category: "Snacks"),
        ])

        // MARK: French Staples
        foods.append(contentsOf: [
            FoodEntry(name: "Camembert", nameFr: nil, brand: nil, caloriesPer100g: 299, carbsPer100g: 0.5, proteinPer100g: 20.0, fatPer100g: 24.0, sodiumMgPer100g: 842, servingSizeGrams: 30, category: "Dairy"),
            FoodEntry(name: "Comté", nameFr: nil, brand: nil, caloriesPer100g: 413, carbsPer100g: 0.5, proteinPer100g: 27.0, fatPer100g: 33.0, sodiumMgPer100g: 590, servingSizeGrams: 30, category: "Dairy"),
            FoodEntry(name: "Emmental", nameFr: nil, brand: nil, caloriesPer100g: 379, carbsPer100g: 0.1, proteinPer100g: 28.0, fatPer100g: 29.0, sodiumMgPer100g: 350, servingSizeGrams: 30, category: "Dairy"),
            FoodEntry(name: "Crème fraîche", nameFr: nil, brand: nil, caloriesPer100g: 292, carbsPer100g: 2.8, proteinPer100g: 2.4, fatPer100g: 30.0, sodiumMgPer100g: 35, servingSizeGrams: 30, category: "Dairy"),
            FoodEntry(name: "Fromage blanc (0%)", nameFr: nil, brand: nil, caloriesPer100g: 48, carbsPer100g: 3.9, proteinPer100g: 7.7, fatPer100g: 0.1, sodiumMgPer100g: 45, servingSizeGrams: 100, category: "Dairy"),
            FoodEntry(name: "Saucisson sec", nameFr: nil, brand: nil, caloriesPer100g: 418, carbsPer100g: 1.5, proteinPer100g: 26.0, fatPer100g: 34.0, sodiumMgPer100g: 1780, servingSizeGrams: 30, category: "Proteins"),
            FoodEntry(name: "Jambon blanc", nameFr: nil, brand: nil, caloriesPer100g: 115, carbsPer100g: 1.0, proteinPer100g: 21.0, fatPer100g: 3.0, sodiumMgPer100g: 900, servingSizeGrams: 40, category: "Proteins"),
            FoodEntry(name: "Semoule, cuite", nameFr: nil, brand: nil, caloriesPer100g: 112, carbsPer100g: 23.5, proteinPer100g: 3.8, fatPer100g: 0.2, sodiumMgPer100g: 5, servingSizeGrams: 200, category: "Grains"),
        ])

        // MARK: Aid Station Foods (see CommonFoodDatabase+AidStation.swift)
        foods.append(contentsOf: Self.aidStationFoods)

        // MARK: Beverages (additional)
        foods.append(contentsOf: [
            FoodEntry(name: "Coca-Cola", nameFr: nil, brand: "Coca-Cola", caloriesPer100g: 42, carbsPer100g: 10.6, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 4, servingSizeGrams: 330, category: "Beverages"),
            FoodEntry(name: "Hot Chocolate", nameFr: "Chocolat chaud", brand: nil, caloriesPer100g: 77, carbsPer100g: 10.7, proteinPer100g: 3.5, fatPer100g: 2.3, sodiumMgPer100g: 45, servingSizeGrams: 250, category: "Beverages"),
            FoodEntry(name: "Green Tea", nameFr: "Thé vert", brand: nil, caloriesPer100g: 1, carbsPer100g: 0.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 1, servingSizeGrams: 240, category: "Beverages"),
        ])

        // MARK: Additional Prepared Meals
        foods.append(contentsOf: [
            FoodEntry(name: "Croque-Monsieur", nameFr: nil, brand: nil, caloriesPer100g: 260, carbsPer100g: 21.0, proteinPer100g: 14.0, fatPer100g: 13.0, sodiumMgPer100g: 600, servingSizeGrams: 150, category: "Meals"),
            FoodEntry(name: "Quiche Lorraine", nameFr: nil, brand: nil, caloriesPer100g: 280, carbsPer100g: 18.0, proteinPer100g: 11.0, fatPer100g: 18.0, sodiumMgPer100g: 450, servingSizeGrams: 150, category: "Meals"),
            FoodEntry(name: "Pasta Bolognese", nameFr: "Pâtes bolognaise", brand: nil, caloriesPer100g: 130, carbsPer100g: 15.0, proteinPer100g: 7.0, fatPer100g: 4.5, sodiumMgPer100g: 300, servingSizeGrams: 300, category: "Meals"),
            FoodEntry(name: "Ratatouille", nameFr: nil, brand: nil, caloriesPer100g: 55, carbsPer100g: 6.0, proteinPer100g: 1.5, fatPer100g: 2.5, sodiumMgPer100g: 200, servingSizeGrams: 200, category: "Meals"),
            FoodEntry(name: "Tabbouleh", nameFr: "Taboulé", brand: nil, caloriesPer100g: 125, carbsPer100g: 15.0, proteinPer100g: 3.0, fatPer100g: 6.0, sodiumMgPer100g: 300, servingSizeGrams: 150, category: "Meals"),
        ])

        return foods
    }()
    // swiftlint:enable function_body_length
}
