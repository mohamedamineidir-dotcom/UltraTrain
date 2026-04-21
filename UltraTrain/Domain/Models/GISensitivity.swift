import Foundation

/// Known gastrointestinal sensitivities that affect product selection.
///
/// Research basis: ~30-70% of endurance athletes experience GI distress during
/// races (Stuempfle & Hoffman 2015). Most common culprits are fructose overload
/// (exceeding intestinal transporter capacity), lactose (dairy-based products),
/// high-fiber solids, and high-fat solids late in ultras. A low-FODMAP window
/// in the 6 days pre-race reduces symptoms in sensitive athletes (JISSN 2019).
enum GISensitivity: String, CaseIterable, Codable, Sendable {
    case lactose
    case fructose
    case fiber
    case fat
    case gluten
    case fodmap

    var displayName: String {
        switch self {
        case .lactose: "Lactose"
        case .fructose: "High fructose"
        case .fiber:   "High fiber"
        case .fat:     "High fat"
        case .gluten:  "Gluten"
        case .fodmap:  "FODMAP foods"
        }
    }
}
