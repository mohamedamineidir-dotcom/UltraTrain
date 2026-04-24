import Foundation

/// Comprehensive catalog of real-brand race-day nutrition products.
///
/// Research-sourced nutrition facts (as of 2026) from:
/// Maurten, SIS, GU, Honey Stinger, Precision Fuel & Hydration, Tailwind,
/// Skratch, LMNT, Nuun, Clif, Spring Energy. Real-food items are commonly
/// used by trail/ultra athletes (Dauwalter, Walmsley, Jornet).
///
/// IDs are stable UUIDs so user product exclusions persist across app updates.
enum DefaultProducts {

    // MARK: - Catalog

    static let all: [NutritionProduct] = gels + chews + drinks + bars + solids + electrolytes

    // MARK: - Gels

    static let gels: [NutritionProduct] = [
        // Maurten
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000001")!,
            name: "Gel 100", type: .gel, brand: "Maurten",
            caloriesPerServing: 100, carbsGramsPerServing: 25, sodiumMgPerServing: 20,
            caffeineMgPerServing: 0, carbRatio: .oneToPointEight, fluidMlPerServing: 0,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowFodmap]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000002")!,
            name: "Gel 100 Caf 100", type: .gel, brand: "Maurten",
            caloriesPerServing: 100, carbsGramsPerServing: 25, sodiumMgPerServing: 20,
            caffeineMgPerServing: 100, carbRatio: .oneToPointEight, fluidMlPerServing: 0,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowFodmap]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000003")!,
            name: "Gel 160", type: .gel, brand: "Maurten",
            caloriesPerServing: 160, carbsGramsPerServing: 40, sodiumMgPerServing: 30,
            caffeineMgPerServing: 0, carbRatio: .oneToPointEight, fluidMlPerServing: 0,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowFodmap]
        ),
        // SIS
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000004")!,
            name: "GO Isotonic", type: .gel, brand: "SIS",
            caloriesPerServing: 87, carbsGramsPerServing: 22, sodiumMgPerServing: 10,
            caffeineMgPerServing: 0, carbRatio: .glucoseOnly, fluidMlPerServing: 0,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000005")!,
            name: "GO Isotonic + Caffeine 75", type: .gel, brand: "SIS",
            caloriesPerServing: 87, carbsGramsPerServing: 22, sodiumMgPerServing: 10,
            caffeineMgPerServing: 75, carbRatio: .glucoseOnly, fluidMlPerServing: 0,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000006")!,
            name: "Beta Fuel Gel", type: .gel, brand: "SIS",
            caloriesPerServing: 160, carbsGramsPerServing: 40, sodiumMgPerServing: 200,
            caffeineMgPerServing: 0, carbRatio: .oneToPointEight, fluidMlPerServing: 0,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        // GU
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000007")!,
            name: "Original", type: .gel, brand: "GU",
            caloriesPerServing: 100, carbsGramsPerServing: 22, sodiumMgPerServing: 60,
            caffeineMgPerServing: 20, carbRatio: .twoToOne, fluidMlPerServing: 200,
            dietaryFlags: [.vegetarian, .glutenFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000008")!,
            name: "Roctane", type: .gel, brand: "GU",
            caloriesPerServing: 100, carbsGramsPerServing: 21, sodiumMgPerServing: 125,
            caffeineMgPerServing: 35, carbRatio: .twoToOne, fluidMlPerServing: 200,
            dietaryFlags: [.vegetarian, .glutenFree, .nutFree]
        ),
        // Precision Fuel
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000009")!,
            name: "PF 30 Gel", type: .gel, brand: "Precision Fuel",
            caloriesPerServing: 120, carbsGramsPerServing: 30, sodiumMgPerServing: 0,
            caffeineMgPerServing: 0, carbRatio: .oneToPointEight, fluidMlPerServing: 200,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000010")!,
            name: "PF 30 Caffeine Gel", type: .gel, brand: "Precision Fuel",
            caloriesPerServing: 120, carbsGramsPerServing: 30, sodiumMgPerServing: 0,
            caffeineMgPerServing: 100, carbRatio: .oneToPointEight, fluidMlPerServing: 200,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000011")!,
            name: "PF 90 Gel", type: .gel, brand: "Precision Fuel",
            caloriesPerServing: 360, carbsGramsPerServing: 90, sodiumMgPerServing: 0,
            caffeineMgPerServing: 0, carbRatio: .oneToPointEight, fluidMlPerServing: 0,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        // Honey Stinger
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000012")!,
            name: "Organic Energy Gel", type: .gel, brand: "Honey Stinger",
            caloriesPerServing: 110, carbsGramsPerServing: 28, sodiumMgPerServing: 50,
            caffeineMgPerServing: 0, carbRatio: .twoToOne, fluidMlPerServing: 200,
            dietaryFlags: [.vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        // Spring Energy
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000013")!,
            name: "Awesome Sauce", type: .gel, brand: "Spring Energy",
            caloriesPerServing: 180, carbsGramsPerServing: 45, sodiumMgPerServing: 60,
            caffeineMgPerServing: 0, carbRatio: .twoToOne, fluidMlPerServing: 150,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000014")!,
            name: "Canaberry", type: .gel, brand: "Spring Energy",
            caloriesPerServing: 140, carbsGramsPerServing: 29, sodiumMgPerServing: 40,
            caffeineMgPerServing: 0, carbRatio: .twoToOne, fluidMlPerServing: 150,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .containsFructose]
        ),
        // Overstim's — major European brand, staple of UTMB / trail-running aid stations
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000015")!,
            name: "Coup de Fouet", type: .gel, brand: "Overstim's",
            caloriesPerServing: 110, carbsGramsPerServing: 26, sodiumMgPerServing: 40,
            caffeineMgPerServing: 50, carbRatio: .glucoseOnly, fluidMlPerServing: 150,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000016")!,
            name: "Gel Antioxydant", type: .gel, brand: "Overstim's",
            caloriesPerServing: 100, carbsGramsPerServing: 24, sodiumMgPerServing: 30,
            caffeineMgPerServing: 0, carbRatio: .glucoseOnly, fluidMlPerServing: 150,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000017")!,
            name: "Gel Long Distance", type: .gel, brand: "Overstim's",
            caloriesPerServing: 115, carbsGramsPerServing: 27, sodiumMgPerServing: 90,
            caffeineMgPerServing: 0, carbRatio: .twoToOne, fluidMlPerServing: 150,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000018")!,
            name: "Gel Caffeiné Long Distance", type: .gel, brand: "Overstim's",
            caloriesPerServing: 115, carbsGramsPerServing: 27, sodiumMgPerServing: 90,
            caffeineMgPerServing: 75, carbRatio: .twoToOne, fluidMlPerServing: 150,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000019")!,
            name: "Gel Endurance", type: .gel, brand: "Overstim's",
            caloriesPerServing: 90, carbsGramsPerServing: 22, sodiumMgPerServing: 30,
            caffeineMgPerServing: 0, carbRatio: .glucoseOnly, fluidMlPerServing: 150,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        // Huma — natural chia-based, popular with ultra-runners who struggle with synthetic gels
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000020")!,
            name: "Original Gel", type: .gel, brand: "Huma",
            caloriesPerServing: 100, carbsGramsPerServing: 23, sodiumMgPerServing: 105,
            caffeineMgPerServing: 0, carbRatio: .twoToOne, fluidMlPerServing: 200,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .containsFructose]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0001-0000-0000-000000000021")!,
            name: "Plus Double Chia Gel", type: .gel, brand: "Huma",
            caloriesPerServing: 120, carbsGramsPerServing: 27, sodiumMgPerServing: 250,
            caffeineMgPerServing: 25, carbRatio: .twoToOne, fluidMlPerServing: 200,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .containsFructose]
        ),
    ]

    // MARK: - Chews

    static let chews: [NutritionProduct] = [
        NutritionProduct(
            id: UUID(uuidString: "11111111-0002-0000-0000-000000000001")!,
            name: "Energy Chews", type: .chew, brand: "Honey Stinger",
            caloriesPerServing: 160, carbsGramsPerServing: 39, sodiumMgPerServing: 80,
            caffeineMgPerServing: 0, carbRatio: .twoToOne, fluidMlPerServing: 250,
            dietaryFlags: [.vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0002-0000-0000-000000000002")!,
            name: "Performance Chews", type: .chew, brand: "Honey Stinger",
            caloriesPerServing: 150, carbsGramsPerServing: 37, sodiumMgPerServing: 160,
            caffeineMgPerServing: 0, carbRatio: .twoToOne, fluidMlPerServing: 250,
            dietaryFlags: [.vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0002-0000-0000-000000000003")!,
            name: "Caffeinated Chews", type: .chew, brand: "Honey Stinger",
            caloriesPerServing: 160, carbsGramsPerServing: 38, sodiumMgPerServing: 130,
            caffeineMgPerServing: 50, carbRatio: .twoToOne, fluidMlPerServing: 250,
            dietaryFlags: [.vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0002-0000-0000-000000000004")!,
            name: "Shot Bloks", type: .chew, brand: "Clif",
            caloriesPerServing: 200, carbsGramsPerServing: 48, sodiumMgPerServing: 140,
            caffeineMgPerServing: 0, carbRatio: .glucoseOnly, fluidMlPerServing: 250,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0002-0000-0000-000000000005")!,
            name: "Energy Chews", type: .chew, brand: "GU",
            caloriesPerServing: 180, carbsGramsPerServing: 44, sodiumMgPerServing: 80,
            caffeineMgPerServing: 0, carbRatio: .twoToOne, fluidMlPerServing: 250,
            dietaryFlags: [.vegetarian, .glutenFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0002-0000-0000-000000000006")!,
            name: "PF 30 Chews", type: .chew, brand: "Precision Fuel",
            caloriesPerServing: 120, carbsGramsPerServing: 30, sodiumMgPerServing: 0,
            caffeineMgPerServing: 0, carbRatio: .oneToPointEight, fluidMlPerServing: 250,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0002-0000-0000-000000000007")!,
            name: "Organic Chews", type: .chew, brand: "Overstim's",
            caloriesPerServing: 130, carbsGramsPerServing: 30, sodiumMgPerServing: 50,
            caffeineMgPerServing: 0, carbRatio: .twoToOne, fluidMlPerServing: 250,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0002-0000-0000-000000000008")!,
            name: "Energy Chews", type: .chew, brand: "Näak",
            caloriesPerServing: 150, carbsGramsPerServing: 35, sodiumMgPerServing: 100,
            caffeineMgPerServing: 0, carbRatio: .twoToOne, fluidMlPerServing: 250,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
    ]

    // MARK: - Drinks

    static let drinks: [NutritionProduct] = [
        NutritionProduct(
            id: UUID(uuidString: "11111111-0003-0000-0000-000000000001")!,
            name: "Drink Mix 160", type: .drink, brand: "Maurten",
            caloriesPerServing: 160, carbsGramsPerServing: 40, sodiumMgPerServing: 50,
            caffeineMgPerServing: 0, carbRatio: .oneToPointEight, fluidMlPerServing: 500,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowFodmap]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0003-0000-0000-000000000002")!,
            name: "Drink Mix 320", type: .drink, brand: "Maurten",
            caloriesPerServing: 320, carbsGramsPerServing: 80, sodiumMgPerServing: 100,
            caffeineMgPerServing: 0, carbRatio: .oneToPointEight, fluidMlPerServing: 500,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowFodmap]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0003-0000-0000-000000000003")!,
            name: "Endurance Fuel", type: .drink, brand: "Tailwind",
            caloriesPerServing: 100, carbsGramsPerServing: 25, sodiumMgPerServing: 303,
            caffeineMgPerServing: 0, carbRatio: .twoToOne, fluidMlPerServing: 500,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0003-0000-0000-000000000004")!,
            name: "Endurance Fuel + Caffeine", type: .drink, brand: "Tailwind",
            caloriesPerServing: 100, carbsGramsPerServing: 25, sodiumMgPerServing: 303,
            caffeineMgPerServing: 35, carbRatio: .twoToOne, fluidMlPerServing: 500,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0003-0000-0000-000000000005")!,
            name: "High-Carb", type: .drink, brand: "Tailwind",
            caloriesPerServing: 200, carbsGramsPerServing: 50, sodiumMgPerServing: 310,
            caffeineMgPerServing: 0, carbRatio: .twoToOne, fluidMlPerServing: 500,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0003-0000-0000-000000000006")!,
            name: "PF 60", type: .drink, brand: "Precision Fuel",
            caloriesPerServing: 240, carbsGramsPerServing: 60, sodiumMgPerServing: 500,
            caffeineMgPerServing: 0, carbRatio: .oneToPointEight, fluidMlPerServing: 500,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0003-0000-0000-000000000007")!,
            name: "Sport Hydration", type: .drink, brand: "Skratch",
            caloriesPerServing: 80, carbsGramsPerServing: 20, sodiumMgPerServing: 380,
            caffeineMgPerServing: 0, carbRatio: .glucoseOnly, fluidMlPerServing: 500,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0003-0000-0000-000000000008")!,
            name: "Beta Fuel Drink", type: .drink, brand: "SIS",
            caloriesPerServing: 320, carbsGramsPerServing: 80, sodiumMgPerServing: 800,
            caffeineMgPerServing: 0, carbRatio: .oneToPointEight, fluidMlPerServing: 500,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        // Overstim's drinks
        NutritionProduct(
            id: UUID(uuidString: "11111111-0003-0000-0000-000000000009")!,
            name: "Hydrixir Antioxydant", type: .drink, brand: "Overstim's",
            caloriesPerServing: 126, carbsGramsPerServing: 31, sodiumMgPerServing: 400,
            caffeineMgPerServing: 0, carbRatio: .twoToOne, fluidMlPerServing: 500,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0003-0000-0000-000000000010")!,
            name: "Hydrixir Long Distance", type: .drink, brand: "Overstim's",
            caloriesPerServing: 140, carbsGramsPerServing: 34, sodiumMgPerServing: 450,
            caffeineMgPerServing: 0, carbRatio: .twoToOne, fluidMlPerServing: 500,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0003-0000-0000-000000000011")!,
            name: "Hydrixir Ultra", type: .drink, brand: "Overstim's",
            caloriesPerServing: 144, carbsGramsPerServing: 34, sodiumMgPerServing: 600,
            caffeineMgPerServing: 0, carbRatio: .twoToOne, fluidMlPerServing: 500,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        // Maurten sports drink extra sizing
        NutritionProduct(
            id: UUID(uuidString: "11111111-0003-0000-0000-000000000012")!,
            name: "Solid C + Sport", type: .drink, brand: "Maurten",
            caloriesPerServing: 100, carbsGramsPerServing: 25, sodiumMgPerServing: 35,
            caffeineMgPerServing: 100, carbRatio: .oneToPointEight, fluidMlPerServing: 500,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowFodmap]
        ),
        // Näak — Canadian brand popular on UTMB / Western States
        NutritionProduct(
            id: UUID(uuidString: "11111111-0003-0000-0000-000000000013")!,
            name: "Hydration Ultra Energy", type: .drink, brand: "Näak",
            caloriesPerServing: 110, carbsGramsPerServing: 26, sodiumMgPerServing: 350,
            caffeineMgPerServing: 0, carbRatio: .twoToOne, fluidMlPerServing: 500,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
    ]

    // MARK: - Bars

    static let bars: [NutritionProduct] = [
        NutritionProduct(
            id: UUID(uuidString: "11111111-0004-0000-0000-000000000001")!,
            name: "Solid 225", type: .bar, brand: "Maurten",
            caloriesPerServing: 225, carbsGramsPerServing: 44, sodiumMgPerServing: 30,
            caffeineMgPerServing: 0, carbRatio: .oneToPointEight,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0004-0000-0000-000000000002")!,
            name: "Bloks Energy Bar", type: .bar, brand: "Clif",
            caloriesPerServing: 250, carbsGramsPerServing: 45, sodiumMgPerServing: 150,
            caffeineMgPerServing: 0, carbRatio: .glucoseOnly,
            dietaryFlags: [.vegan, .vegetarian, .highFiber]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0004-0000-0000-000000000003")!,
            name: "Energy Waffle", type: .bar, brand: "Honey Stinger",
            caloriesPerServing: 160, carbsGramsPerServing: 21, sodiumMgPerServing: 55,
            caffeineMgPerServing: 0, carbRatio: .twoToOne,
            dietaryFlags: [.vegetarian]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0004-0000-0000-000000000004")!,
            name: "Stroopwafel", type: .bar, brand: "GU",
            caloriesPerServing: 140, carbsGramsPerServing: 21, sodiumMgPerServing: 60,
            caffeineMgPerServing: 0, carbRatio: .twoToOne,
            dietaryFlags: [.vegetarian]
        ),
        // Overstim's — Gatosport is a rice-cake-style pre-race/during-race staple in Europe
        NutritionProduct(
            id: UUID(uuidString: "11111111-0004-0000-0000-000000000005")!,
            name: "Gatosport", type: .bar, brand: "Overstim's",
            caloriesPerServing: 180, carbsGramsPerServing: 36, sodiumMgPerServing: 120,
            caffeineMgPerServing: 0, carbRatio: .twoToOne,
            dietaryFlags: [.vegetarian]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0004-0000-0000-000000000006")!,
            name: "Barre Energétique", type: .bar, brand: "Overstim's",
            caloriesPerServing: 155, carbsGramsPerServing: 28, sodiumMgPerServing: 55,
            caffeineMgPerServing: 0, carbRatio: .twoToOne,
            dietaryFlags: [.vegetarian]
        ),
        // Näak
        NutritionProduct(
            id: UUID(uuidString: "11111111-0004-0000-0000-000000000007")!,
            name: "Ultra Energy Bar", type: .bar, brand: "Näak",
            caloriesPerServing: 200, carbsGramsPerServing: 35, sodiumMgPerServing: 110,
            caffeineMgPerServing: 0, carbRatio: .twoToOne,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        // Spring Energy
        NutritionProduct(
            id: UUID(uuidString: "11111111-0004-0000-0000-000000000008")!,
            name: "Speednut Bar", type: .bar, brand: "Spring Energy",
            caloriesPerServing: 200, carbsGramsPerServing: 28, sodiumMgPerServing: 80,
            caffeineMgPerServing: 0, carbRatio: .twoToOne,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree]
        ),
    ]

    // MARK: - Solids (real food)

    static let solids: [NutritionProduct] = [
        NutritionProduct(
            id: UUID(uuidString: "11111111-0005-0000-0000-000000000001")!,
            name: "Boiled Potato (salted)", type: .realFood,
            caloriesPerServing: 120, carbsGramsPerServing: 26, sodiumMgPerServing: 400,
            caffeineMgPerServing: 0, carbRatio: .glucoseOnly,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowFodmap]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0005-0000-0000-000000000002")!,
            name: "Banana", type: .realFood,
            caloriesPerServing: 105, carbsGramsPerServing: 27, sodiumMgPerServing: 1,
            caffeineMgPerServing: 0, carbRatio: .twoToOne,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .containsFructose]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0005-0000-0000-000000000003")!,
            name: "Rice Ball (Onigiri)", type: .realFood,
            caloriesPerServing: 180, carbsGramsPerServing: 38, sodiumMgPerServing: 350,
            caffeineMgPerServing: 0, carbRatio: .glucoseOnly,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowFodmap]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0005-0000-0000-000000000004")!,
            name: "PB & J Quarter", type: .realFood,
            caloriesPerServing: 160, carbsGramsPerServing: 22, sodiumMgPerServing: 200,
            caffeineMgPerServing: 0, carbRatio: .twoToOne,
            dietaryFlags: [.vegetarian, .highFat]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0005-0000-0000-000000000005")!,
            name: "Pretzels (handful)", type: .realFood,
            caloriesPerServing: 110, carbsGramsPerServing: 23, sodiumMgPerServing: 380,
            caffeineMgPerServing: 0, carbRatio: .glucoseOnly,
            dietaryFlags: [.vegan, .vegetarian, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0005-0000-0000-000000000006")!,
            name: "Bone Broth Cup", type: .realFood,
            caloriesPerServing: 40, carbsGramsPerServing: 2, sodiumMgPerServing: 600,
            caffeineMgPerServing: 0, carbRatio: .glucoseOnly, fluidMlPerServing: 250,
            dietaryFlags: [.glutenFree, .dairyFree, .nutFree, .lowFodmap]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0005-0000-0000-000000000007")!,
            name: "Applesauce Pouch", type: .realFood,
            caloriesPerServing: 60, carbsGramsPerServing: 15, sodiumMgPerServing: 0,
            caffeineMgPerServing: 0, carbRatio: .twoToOne, fluidMlPerServing: 0,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .containsFructose]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0005-0000-0000-000000000008")!,
            name: "Medjool Date", type: .realFood,
            caloriesPerServing: 66, carbsGramsPerServing: 18, sodiumMgPerServing: 0,
            caffeineMgPerServing: 0, carbRatio: .twoToOne,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .containsFructose, .highFiber]
        ),
    ]

    // MARK: - Electrolyte / salt

    static let electrolytes: [NutritionProduct] = [
        NutritionProduct(
            id: UUID(uuidString: "11111111-0006-0000-0000-000000000001")!,
            name: "Salt Capsule", type: .salt,
            caloriesPerServing: 0, carbsGramsPerServing: 0, sodiumMgPerServing: 215,
            caffeineMgPerServing: 0, carbRatio: nil,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowFodmap]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0006-0000-0000-000000000002")!,
            name: "LMNT Recharge", type: .salt, brand: "LMNT",
            caloriesPerServing: 10, carbsGramsPerServing: 2, sodiumMgPerServing: 1000,
            caffeineMgPerServing: 0, carbRatio: nil, fluidMlPerServing: 500,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0006-0000-0000-000000000003")!,
            name: "PH 1000", type: .salt, brand: "Precision Fuel",
            caloriesPerServing: 16, carbsGramsPerServing: 4, sodiumMgPerServing: 1000,
            caffeineMgPerServing: 0, carbRatio: nil, fluidMlPerServing: 500,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0006-0000-0000-000000000004")!,
            name: "PH 1500", type: .salt, brand: "Precision Fuel",
            caloriesPerServing: 16, carbsGramsPerServing: 4, sodiumMgPerServing: 1500,
            caffeineMgPerServing: 0, carbRatio: nil, fluidMlPerServing: 500,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0006-0000-0000-000000000005")!,
            name: "Sport Tablets", type: .salt, brand: "Nuun",
            caloriesPerServing: 15, carbsGramsPerServing: 4, sodiumMgPerServing: 300,
            caffeineMgPerServing: 0, carbRatio: nil, fluidMlPerServing: 500,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0006-0000-0000-000000000006")!,
            name: "Elektrolytes", type: .salt, brand: "Overstim's",
            caloriesPerServing: 0, carbsGramsPerServing: 0, sodiumMgPerServing: 500,
            caffeineMgPerServing: 0, carbRatio: nil, fluidMlPerServing: 500,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowFodmap]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0006-0000-0000-000000000007")!,
            name: "Fast Chews", type: .salt, brand: "SaltStick",
            caloriesPerServing: 10, carbsGramsPerServing: 3, sodiumMgPerServing: 100,
            caffeineMgPerServing: 0, carbRatio: nil, fluidMlPerServing: 0,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowFodmap]
        ),
        NutritionProduct(
            id: UUID(uuidString: "11111111-0006-0000-0000-000000000008")!,
            name: "Salt Caps", type: .salt, brand: "SaltStick",
            caloriesPerServing: 0, carbsGramsPerServing: 0, sodiumMgPerServing: 215,
            caffeineMgPerServing: 0, carbRatio: nil, fluidMlPerServing: 0,
            dietaryFlags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowFodmap]
        ),
    ]

    // MARK: - Legacy accessors (kept so the existing generator still compiles)

    static var gel: NutritionProduct { all.first { $0.type == .gel && !$0.caffeinated }! }
    static var caffeineGel: NutritionProduct { all.first { $0.type == .gel && $0.caffeinated }! }
    static var bar: NutritionProduct { all.first { $0.type == .bar }! }
    static var drink: NutritionProduct { all.first { $0.type == .drink }! }
    static var chew: NutritionProduct { all.first { $0.type == .chew && !$0.caffeinated }! }
    static var caffeineChew: NutritionProduct { all.first { $0.type == .chew && $0.caffeinated }! }
    static var realFood: NutritionProduct { all.first { $0.type == .realFood }! }
    static var saltCapsule: NutritionProduct { all.first { $0.type == .salt }! }
}
