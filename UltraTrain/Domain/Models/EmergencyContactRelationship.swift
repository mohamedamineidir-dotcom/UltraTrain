import Foundation

enum EmergencyContactRelationship: String, CaseIterable, Sendable, Codable {
    case spouse
    case partner
    case parent
    case sibling
    case friend
    case coach
    case crewMember
    case other

    var displayName: String {
        switch self {
        case .spouse: return "Spouse"
        case .partner: return "Partner"
        case .parent: return "Parent"
        case .sibling: return "Sibling"
        case .friend: return "Friend"
        case .coach: return "Coach"
        case .crewMember: return "Crew Member"
        case .other: return "Other"
        }
    }
}
