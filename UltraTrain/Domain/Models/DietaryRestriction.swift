import Foundation

/// Ethical or medical dietary restrictions that filter product selection.
enum DietaryRestriction: String, CaseIterable, Codable, Sendable {
    case vegan
    case vegetarian
    case glutenFree
    case dairyFree
    case nutFree

    var displayName: String {
        switch self {
        case .vegan:      String(localized: "diet.vegan", defaultValue: "Vegan")
        case .vegetarian: String(localized: "diet.vegetarian", defaultValue: "Vegetarian")
        case .glutenFree: String(localized: "diet.glutenFree", defaultValue: "Gluten-free")
        case .dairyFree:  String(localized: "diet.dairyFree", defaultValue: "Dairy-free")
        case .nutFree:    String(localized: "diet.nutFree", defaultValue: "Nut-free")
        }
    }
}
