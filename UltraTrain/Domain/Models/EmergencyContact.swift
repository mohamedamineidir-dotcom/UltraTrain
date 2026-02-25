import Foundation

struct EmergencyContact: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var phoneNumber: String
    var relationship: EmergencyContactRelationship
    var isEnabled: Bool

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
