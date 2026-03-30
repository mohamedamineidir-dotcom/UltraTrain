import Foundation

enum InjuryCount: String, CaseIterable, Sendable, Codable {
    case none
    case one
    case two
    case threeOrMore

    var displayName: String {
        switch self {
        case .none:        "None"
        case .one:         "1 injury"
        case .two:         "2 injuries"
        case .threeOrMore: "3+ injuries"
        }
    }
}
