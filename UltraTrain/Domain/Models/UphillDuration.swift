import Foundation

enum UphillDuration: String, CaseIterable, Sendable, Codable {
    case none
    case upTo2Min
    case upTo4Min
    case upTo6Min
    case upTo8Min
    case over8Min

    var displayName: String {
        switch self {
        case .none:     "No uphill nearby"
        case .upTo2Min: "Up to 2 min"
        case .upTo4Min: "2–4 min"
        case .upTo6Min: "4–6 min"
        case .upTo8Min: "6–8 min"
        case .over8Min: "8+ min (long climb)"
        }
    }
}
