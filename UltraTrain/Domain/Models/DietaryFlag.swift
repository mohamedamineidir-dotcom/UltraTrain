import Foundation

/// Dietary properties of a nutrition product — used to filter the catalog
/// against the athlete's DietaryRestriction and GISensitivity sets.
enum DietaryFlag: String, CaseIterable, Codable, Sendable {
    case vegan
    case vegetarian
    case glutenFree
    case dairyFree
    case nutFree
    case containsLactose
    case containsFructose
    case highFiber
    case highFat
    case lowFodmap
}
