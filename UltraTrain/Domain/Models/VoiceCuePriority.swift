import Foundation

enum VoiceCuePriority: Int, Comparable, Sendable {
    case low = 0
    case medium = 1
    case high = 2

    static func < (lhs: VoiceCuePriority, rhs: VoiceCuePriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
