import Foundation

enum ChallengeDuration: String, CaseIterable, Sendable {
    case oneWeek
    case twoWeeks
    case oneMonth

    var days: Int {
        switch self {
        case .oneWeek: return 7
        case .twoWeeks: return 14
        case .oneMonth: return 30
        }
    }

    var displayName: String {
        switch self {
        case .oneWeek: return "1 Week"
        case .twoWeeks: return "2 Weeks"
        case .oneMonth: return "1 Month"
        }
    }
}
