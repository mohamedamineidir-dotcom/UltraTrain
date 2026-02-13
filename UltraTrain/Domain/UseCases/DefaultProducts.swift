import Foundation

enum DefaultProducts {
    static let all: [NutritionProduct] = [
        NutritionProduct(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Energy Gel",
            type: .gel,
            caloriesPerServing: 100,
            carbsGramsPerServing: 25.0,
            sodiumMgPerServing: 60,
            caffeinated: false
        ),
        NutritionProduct(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Caffeine Gel",
            type: .gel,
            caloriesPerServing: 100,
            carbsGramsPerServing: 25.0,
            sodiumMgPerServing: 60,
            caffeinated: true
        ),
        NutritionProduct(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "Energy Bar",
            type: .bar,
            caloriesPerServing: 250,
            carbsGramsPerServing: 40.0,
            sodiumMgPerServing: 200,
            caffeinated: false
        ),
        NutritionProduct(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            name: "Electrolyte Drink Mix",
            type: .drink,
            caloriesPerServing: 80,
            carbsGramsPerServing: 20.0,
            sodiumMgPerServing: 300,
            caffeinated: false
        ),
        NutritionProduct(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            name: "Energy Chews",
            type: .chew,
            caloriesPerServing: 90,
            carbsGramsPerServing: 24.0,
            sodiumMgPerServing: 50,
            caffeinated: false
        ),
        NutritionProduct(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            name: "Caffeine Chews",
            type: .chew,
            caloriesPerServing: 90,
            carbsGramsPerServing: 24.0,
            sodiumMgPerServing: 50,
            caffeinated: true
        ),
        NutritionProduct(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
            name: "Boiled Potato (salted)",
            type: .realFood,
            caloriesPerServing: 120,
            carbsGramsPerServing: 26.0,
            sodiumMgPerServing: 400,
            caffeinated: false
        ),
        NutritionProduct(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
            name: "Salt Capsule",
            type: .salt,
            caloriesPerServing: 0,
            carbsGramsPerServing: 0.0,
            sodiumMgPerServing: 215,
            caffeinated: false
        ),
    ]

    static var gel: NutritionProduct { all.first { $0.type == .gel && !$0.caffeinated }! }
    static var caffeineGel: NutritionProduct { all.first { $0.type == .gel && $0.caffeinated }! }
    static var bar: NutritionProduct { all.first { $0.type == .bar }! }
    static var drink: NutritionProduct { all.first { $0.type == .drink }! }
    static var chew: NutritionProduct { all.first { $0.type == .chew && !$0.caffeinated }! }
    static var caffeineChew: NutritionProduct { all.first { $0.type == .chew && $0.caffeinated }! }
    static var realFood: NutritionProduct { all.first { $0.type == .realFood }! }
    static var saltCapsule: NutritionProduct { all.first { $0.type == .salt }! }
}
