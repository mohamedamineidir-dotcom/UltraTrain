import Foundation

enum EmergencyContactSwiftDataMapper {

    static func toDomain(_ model: EmergencyContactSwiftDataModel) -> EmergencyContact {
        EmergencyContact(
            id: model.contactId,
            name: model.name,
            phoneNumber: model.phoneNumber,
            relationship: EmergencyContactRelationship(rawValue: model.relationship) ?? .other,
            isEnabled: model.isEnabled
        )
    }

    static func toSwiftData(_ contact: EmergencyContact) -> EmergencyContactSwiftDataModel {
        EmergencyContactSwiftDataModel(
            contactId: contact.id,
            name: contact.name,
            phoneNumber: contact.phoneNumber,
            relationship: contact.relationship.rawValue,
            isEnabled: contact.isEnabled
        )
    }
}
