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
        case .spouse: return String(localized: "ecr.spouse", defaultValue: "Spouse")
        case .partner: return String(localized: "ecr.partner", defaultValue: "Partner")
        case .parent: return String(localized: "ecr.parent", defaultValue: "Parent")
        case .sibling: return String(localized: "ecr.sibling", defaultValue: "Sibling")
        case .friend: return String(localized: "ecr.friend", defaultValue: "Friend")
        case .coach: return String(localized: "ecr.coach", defaultValue: "Coach")
        case .crewMember: return String(localized: "ecr.crew", defaultValue: "Crew Member")
        case .other: return String(localized: "ecr.other", defaultValue: "Other")
        }
    }
}
