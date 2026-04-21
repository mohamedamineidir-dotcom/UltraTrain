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
        case .vegan:      "Vegan"
        case .vegetarian: "Vegetarian"
        case .glutenFree: "Gluten-free"
        case .dairyFree:  "Dairy-free"
        case .nutFree:    "Nut-free"
        }
    }
}
