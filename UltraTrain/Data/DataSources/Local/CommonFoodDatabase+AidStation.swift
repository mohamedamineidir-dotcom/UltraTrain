import Foundation

// MARK: - Trail Race Aid Station & Ultra Running Foods

extension CommonFoodDatabase {

    static let aidStationFoods: [FoodEntry] = [

        // MARK: Broths & Soups (ultra staple at night aid stations)

        FoodEntry(name: "Chicken Broth", nameFr: "Bouillon de poulet", brand: nil, caloriesPer100g: 5,
                  carbsPer100g: 0.3, proteinPer100g: 0.5, fatPer100g: 0.0, sodiumMgPer100g: 343, servingSizeGrams: 240, category: "Aid Station"),
        FoodEntry(name: "Beef Broth", nameFr: "Bouillon de bœuf", brand: nil, caloriesPer100g: 8,
                  carbsPer100g: 0.1, proteinPer100g: 1.3, fatPer100g: 0.0, sodiumMgPer100g: 400, servingSizeGrams: 240, category: "Aid Station"),
        FoodEntry(name: "Miso Soup", nameFr: "Soupe miso", brand: nil, caloriesPer100g: 33,
                  carbsPer100g: 3.5, proteinPer100g: 2.5, fatPer100g: 1.0, sodiumMgPer100g: 500, servingSizeGrams: 200, category: "Aid Station"),
        FoodEntry(name: "Cup Noodles / Ramen", nameFr: "Nouilles instantanées", brand: nil, caloriesPer100g: 78,
                  carbsPer100g: 10.0, proteinPer100g: 2.0, fatPer100g: 3.5, sodiumMgPer100g: 700, servingSizeGrams: 350, category: "Aid Station"),

        // MARK: Sandwiches & Wraps

        FoodEntry(name: "PB&J Sandwich", nameFr: "Sandwich beurre de cacahuète-confiture", brand: nil, caloriesPer100g: 330,
                  carbsPer100g: 40.0, proteinPer100g: 10.0, fatPer100g: 15.0, sodiumMgPer100g: 400, servingSizeGrams: 100, category: "Aid Station"),
        FoodEntry(name: "Turkey & Cheese Wrap", nameFr: "Wrap dinde-fromage", brand: nil, caloriesPer100g: 195,
                  carbsPer100g: 15.0, proteinPer100g: 14.0, fatPer100g: 10.0, sodiumMgPer100g: 500, servingSizeGrams: 150, category: "Aid Station"),
        FoodEntry(name: "Quesadilla", nameFr: nil, brand: nil, caloriesPer100g: 245,
                  carbsPer100g: 20.0, proteinPer100g: 12.0, fatPer100g: 14.0, sodiumMgPer100g: 450, servingSizeGrams: 130, category: "Aid Station"),
        FoodEntry(name: "Grilled Cheese Sandwich", nameFr: "Croque-fromage", brand: nil, caloriesPer100g: 280,
                  carbsPer100g: 23.0, proteinPer100g: 12.0, fatPer100g: 16.0, sodiumMgPer100g: 600, servingSizeGrams: 130, category: "Aid Station"),

        // MARK: Savory Trail Foods

        FoodEntry(name: "Rice Ball (Onigiri)", nameFr: "Boulette de riz", brand: nil, caloriesPer100g: 160,
                  carbsPer100g: 36.0, proteinPer100g: 2.5, fatPer100g: 0.3, sodiumMgPer100g: 200, servingSizeGrams: 100, category: "Aid Station"),
        FoodEntry(name: "Boiled Potato, Salted (Aid Station)", nameFr: "Pomme de terre salée", brand: nil, caloriesPer100g: 87,
                  carbsPer100g: 20.1, proteinPer100g: 1.9, fatPer100g: 0.1, sodiumMgPer100g: 240, servingSizeGrams: 150, category: "Aid Station"),
        FoodEntry(name: "Boiled Egg, Salted", nameFr: "Œuf dur salé", brand: nil, caloriesPer100g: 155,
                  carbsPer100g: 1.1, proteinPer100g: 13.0, fatPer100g: 11.0, sodiumMgPer100g: 450, servingSizeGrams: 50, category: "Aid Station"),
        FoodEntry(name: "Pickle", nameFr: "Cornichon", brand: nil, caloriesPer100g: 11,
                  carbsPer100g: 2.3, proteinPer100g: 0.3, fatPer100g: 0.2, sodiumMgPer100g: 1208, servingSizeGrams: 65, category: "Aid Station"),
        FoodEntry(name: "Pickle Juice (shot)", nameFr: "Jus de cornichon", brand: nil, caloriesPer100g: 0,
                  carbsPer100g: 0.0, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 1500, servingSizeGrams: 60, category: "Aid Station"),
        FoodEntry(name: "Bacon Strip", nameFr: "Tranche de bacon", brand: nil, caloriesPer100g: 541,
                  carbsPer100g: 1.4, proteinPer100g: 37.0, fatPer100g: 42.0, sodiumMgPer100g: 1717, servingSizeGrams: 8, category: "Aid Station"),
        FoodEntry(name: "Potato Chips", nameFr: "Chips", brand: nil, caloriesPer100g: 536,
                  carbsPer100g: 50.0, proteinPer100g: 7.0, fatPer100g: 35.0, sodiumMgPer100g: 600, servingSizeGrams: 30, category: "Aid Station"),
        FoodEntry(name: "Tortilla Chips, Salted", nameFr: "Tortilla chips", brand: nil, caloriesPer100g: 489,
                  carbsPer100g: 63.0, proteinPer100g: 7.0, fatPer100g: 24.0, sodiumMgPer100g: 420, servingSizeGrams: 30, category: "Aid Station"),

        // MARK: Sweet Trail Foods

        FoodEntry(name: "Fig Bars (Fig Newtons)", nameFr: "Barres aux figues", brand: nil, caloriesPer100g: 350,
                  carbsPer100g: 70.0, proteinPer100g: 3.5, fatPer100g: 7.0, sodiumMgPer100g: 200, servingSizeGrams: 56, category: "Aid Station"),
        FoodEntry(name: "Baby Food Fruit Puree", nameFr: "Compote bébé", brand: nil, caloriesPer100g: 50,
                  carbsPer100g: 11.0, proteinPer100g: 0.5, fatPer100g: 0.2, sodiumMgPer100g: 5, servingSizeGrams: 90, category: "Aid Station"),
        FoodEntry(name: "Stroopwafel (Generic)", nameFr: "Gaufre au sirop", brand: nil, caloriesPer100g: 450,
                  carbsPer100g: 67.0, proteinPer100g: 3.0, fatPer100g: 19.0, sodiumMgPer100g: 180, servingSizeGrams: 30, category: "Aid Station"),
        FoodEntry(name: "Swedish Fish / Gummy Candy", nameFr: "Bonbons gélifiés", brand: nil, caloriesPer100g: 343,
                  carbsPer100g: 80.0, proteinPer100g: 5.0, fatPer100g: 0.1, sodiumMgPer100g: 50, servingSizeGrams: 40, category: "Aid Station"),
        FoodEntry(name: "Fruit Cup (canned)", nameFr: "Cocktail de fruits", brand: nil, caloriesPer100g: 57,
                  carbsPer100g: 14.7, proteinPer100g: 0.4, fatPer100g: 0.1, sodiumMgPer100g: 5, servingSizeGrams: 120, category: "Aid Station"),

        // MARK: Beverages (Aid Station)

        FoodEntry(name: "Flat Coca-Cola (Aid Station)", nameFr: "Coca-Cola dégazé", brand: "Coca-Cola", caloriesPer100g: 42,
                  carbsPer100g: 10.6, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 4, servingSizeGrams: 200, category: "Aid Station"),
        FoodEntry(name: "Mountain Dew", nameFr: nil, brand: "Mountain Dew", caloriesPer100g: 48,
                  carbsPer100g: 12.3, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 24, servingSizeGrams: 355, category: "Aid Station"),
        FoodEntry(name: "Ginger Ale", nameFr: nil, brand: nil, caloriesPer100g: 34,
                  carbsPer100g: 8.8, proteinPer100g: 0.0, fatPer100g: 0.0, sodiumMgPer100g: 12, servingSizeGrams: 355, category: "Aid Station"),
    ]
}
