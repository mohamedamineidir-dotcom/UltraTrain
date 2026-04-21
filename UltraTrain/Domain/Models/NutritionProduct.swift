import Foundation

/// A race-day or training nutrition product — gel, chew, drink, bar, solid, salt.
///
/// All nutritional fields describe ONE serving as typically consumed
/// (one gel, one sachet, one bar, one fist-size potato, one capsule).
struct NutritionProduct: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    var name: String
    var type: ProductType
    var brand: String?
    var caloriesPerServing: Int
    var carbsGramsPerServing: Double
    var sodiumMgPerServing: Int
    var caffeineMgPerServing: Int
    var carbRatio: CarbRatio?
    /// Recommended fluid volume to consume with this product (drinks: bottle
    /// volume; gels: flush-down water; solids: nil).
    var fluidMlPerServing: Int?
    var dietaryFlags: Set<DietaryFlag>

    var caffeinated: Bool { caffeineMgPerServing > 0 }

    // MARK: - Backwards-compatible Codable

    /// Legacy records (pre-brand/caffeineMg/carbRatio) decode cleanly by
    /// treating missing fields as nil/0 and mapping the old `caffeinated` bool
    /// to a 25 mg default if it was true.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.type = try c.decode(ProductType.self, forKey: .type)
        self.brand = try c.decodeIfPresent(String.self, forKey: .brand)
        self.caloriesPerServing = try c.decode(Int.self, forKey: .caloriesPerServing)
        self.carbsGramsPerServing = try c.decode(Double.self, forKey: .carbsGramsPerServing)
        self.sodiumMgPerServing = try c.decode(Int.self, forKey: .sodiumMgPerServing)
        if let mg = try c.decodeIfPresent(Int.self, forKey: .caffeineMgPerServing) {
            self.caffeineMgPerServing = mg
        } else if let caffeinated = try c.decodeIfPresent(Bool.self, forKey: .caffeinated), caffeinated {
            self.caffeineMgPerServing = 25 // legacy default
        } else {
            self.caffeineMgPerServing = 0
        }
        self.carbRatio = try c.decodeIfPresent(CarbRatio.self, forKey: .carbRatio)
        self.fluidMlPerServing = try c.decodeIfPresent(Int.self, forKey: .fluidMlPerServing)
        let flags: Set<DietaryFlag>? = try c.decodeIfPresent(Set<DietaryFlag>.self, forKey: .dietaryFlags)
        self.dietaryFlags = flags ?? Set<DietaryFlag>()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(type, forKey: .type)
        try c.encodeIfPresent(brand, forKey: .brand)
        try c.encode(caloriesPerServing, forKey: .caloriesPerServing)
        try c.encode(carbsGramsPerServing, forKey: .carbsGramsPerServing)
        try c.encode(sodiumMgPerServing, forKey: .sodiumMgPerServing)
        try c.encode(caffeineMgPerServing, forKey: .caffeineMgPerServing)
        try c.encode(caffeinated, forKey: .caffeinated)
        try c.encodeIfPresent(carbRatio, forKey: .carbRatio)
        try c.encodeIfPresent(fluidMlPerServing, forKey: .fluidMlPerServing)
        try c.encode(dietaryFlags, forKey: .dietaryFlags)
    }

    init(
        id: UUID,
        name: String,
        type: ProductType,
        brand: String? = nil,
        caloriesPerServing: Int,
        carbsGramsPerServing: Double,
        sodiumMgPerServing: Int,
        caffeineMgPerServing: Int = 0,
        carbRatio: CarbRatio? = nil,
        fluidMlPerServing: Int? = nil,
        dietaryFlags: Set<DietaryFlag> = []
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.brand = brand
        self.caloriesPerServing = caloriesPerServing
        self.carbsGramsPerServing = carbsGramsPerServing
        self.sodiumMgPerServing = sodiumMgPerServing
        self.caffeineMgPerServing = caffeineMgPerServing
        self.carbRatio = carbRatio
        self.fluidMlPerServing = fluidMlPerServing
        self.dietaryFlags = dietaryFlags
    }

    /// Legacy convenience init kept for callers that still pass a boolean
    /// `caffeinated` flag. Maps true → 25 mg, false → 0.
    init(
        id: UUID,
        name: String,
        type: ProductType,
        caloriesPerServing: Int,
        carbsGramsPerServing: Double,
        sodiumMgPerServing: Int,
        caffeinated: Bool
    ) {
        self.init(
            id: id,
            name: name,
            type: type,
            caloriesPerServing: caloriesPerServing,
            carbsGramsPerServing: carbsGramsPerServing,
            sodiumMgPerServing: sodiumMgPerServing,
            caffeineMgPerServing: caffeinated ? 25 : 0
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, type, brand
        case caloriesPerServing, carbsGramsPerServing, sodiumMgPerServing
        case caffeineMgPerServing, caffeinated
        case carbRatio, fluidMlPerServing, dietaryFlags
    }
}
