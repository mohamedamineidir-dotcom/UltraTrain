import Foundation
@testable import UltraTrain

final class MockEmergencyContactRepository: EmergencyContactRepository, @unchecked Sendable {
    var contacts: [EmergencyContact] = []
    var shouldThrow = false

    var getContactsCalled = false
    var getContactByIdCalled = false
    var saveContactCalled = false
    var updateContactCalled = false
    var deleteContactCalled = false
    var deletedId: UUID?

    func getContacts() async throws -> [EmergencyContact] {
        getContactsCalled = true
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return contacts
    }

    func getContact(id: UUID) async throws -> EmergencyContact? {
        getContactByIdCalled = true
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return contacts.first { $0.id == id }
    }

    func saveContact(_ contact: EmergencyContact) async throws {
        saveContactCalled = true
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        contacts.append(contact)
    }

    func updateContact(_ contact: EmergencyContact) async throws {
        updateContactCalled = true
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
            contacts[index] = contact
        }
    }

    func deleteContact(id: UUID) async throws {
        deleteContactCalled = true
        deletedId = id
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        contacts.removeAll { $0.id == id }
    }
}
