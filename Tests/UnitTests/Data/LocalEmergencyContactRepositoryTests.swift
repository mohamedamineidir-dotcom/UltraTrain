import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalEmergencyContactRepository Tests")
@MainActor
struct LocalEmergencyContactRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([EmergencyContactSwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeContact(
        id: UUID = UUID(),
        name: String = "Marie",
        phoneNumber: String = "+33612345678",
        relationship: EmergencyContactRelationship = .spouse,
        isEnabled: Bool = true
    ) -> EmergencyContact {
        EmergencyContact(
            id: id,
            name: name,
            phoneNumber: phoneNumber,
            relationship: relationship,
            isEnabled: isEnabled
        )
    }

    @Test("Save and fetch contacts")
    func saveAndFetchContacts() async throws {
        let container = try makeContainer()
        let repo = LocalEmergencyContactRepository(modelContainer: container)

        let contact = makeContact(name: "Jean")
        try await repo.saveContact(contact)

        let results = try await repo.getContacts()
        #expect(results.count == 1)
        #expect(results.first?.name == "Jean")
    }

    @Test("Get contact by ID returns matching contact")
    func getContactByIdReturnsMatching() async throws {
        let container = try makeContainer()
        let repo = LocalEmergencyContactRepository(modelContainer: container)
        let contactId = UUID()

        try await repo.saveContact(makeContact(id: contactId, name: "Pierre"))

        let fetched = try await repo.getContact(id: contactId)
        #expect(fetched != nil)
        #expect(fetched?.name == "Pierre")
    }

    @Test("Get contact by ID returns nil for unknown ID")
    func getContactByIdReturnsNilForUnknown() async throws {
        let container = try makeContainer()
        let repo = LocalEmergencyContactRepository(modelContainer: container)

        let fetched = try await repo.getContact(id: UUID())
        #expect(fetched == nil)
    }

    @Test("Update contact modifies fields")
    func updateContactModifiesFields() async throws {
        let container = try makeContainer()
        let repo = LocalEmergencyContactRepository(modelContainer: container)
        let contactId = UUID()

        try await repo.saveContact(makeContact(id: contactId, name: "Old Name", phoneNumber: "+33100000000"))

        let updated = EmergencyContact(
            id: contactId,
            name: "New Name",
            phoneNumber: "+33199999999",
            relationship: .coach,
            isEnabled: false
        )
        try await repo.updateContact(updated)

        let fetched = try await repo.getContact(id: contactId)
        #expect(fetched?.name == "New Name")
        #expect(fetched?.phoneNumber == "+33199999999")
        #expect(fetched?.relationship == .coach)
        #expect(fetched?.isEnabled == false)
    }

    @Test("Update contact throws when not found")
    func updateContactThrowsWhenNotFound() async throws {
        let container = try makeContainer()
        let repo = LocalEmergencyContactRepository(modelContainer: container)

        let contact = makeContact()
        await #expect(throws: DomainError.self) {
            try await repo.updateContact(contact)
        }
    }

    @Test("Delete contact removes it")
    func deleteContactRemovesIt() async throws {
        let container = try makeContainer()
        let repo = LocalEmergencyContactRepository(modelContainer: container)
        let contactId = UUID()

        try await repo.saveContact(makeContact(id: contactId))
        try await repo.deleteContact(id: contactId)

        let fetched = try await repo.getContact(id: contactId)
        #expect(fetched == nil)
    }
}
