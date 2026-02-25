import Foundation

enum AdjustmentSeverity: String, Comparable, Sendable {
    case suggestion
    case recommended
    case urgent

    private var sortOrder: Int {
        switch self {
        case .urgent: 2
        case .recommended: 1
        case .suggestion: 0
        }
    }

    static func < (lhs: AdjustmentSeverity, rhs: AdjustmentSeverity) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
