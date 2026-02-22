import Foundation
import SwiftData

@Model
final class EmergencyContactSwiftDataModel {
    var contactId: UUID = UUID()
    var name: String = ""
    var phoneNumber: String = ""
    var relationship: String = "friend"
    var isEnabled: Bool = true

    init(
        contactId: UUID = UUID(),
        name: String = "",
        phoneNumber: String = "",
        relationship: String = "friend",
        isEnabled: Bool = true
    ) {
        self.contactId = contactId
        self.name = name
        self.phoneNumber = phoneNumber
        self.relationship = relationship
        self.isEnabled = isEnabled
    }
}
