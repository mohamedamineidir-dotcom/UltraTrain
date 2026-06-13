import Foundation

enum InjuryCount: String, CaseIterable, Sendable, Codable {
    case none
    case one
    case two
    case threeOrMore

    var displayName: String {
        switch self {
        case .none:        String(localized: "injc.none", defaultValue: "None")
        case .one:         String(localized: "injc.one", defaultValue: "1 injury")
        case .two:         String(localized: "injc.two", defaultValue: "2 injuries")
        case .threeOrMore: String(localized: "injc.three", defaultValue: "3+ injuries")
        }
    }
}
