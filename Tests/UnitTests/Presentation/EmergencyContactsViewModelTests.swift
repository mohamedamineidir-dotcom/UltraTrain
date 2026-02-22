import Foundation
import Testing
@testable import UltraTrain

@MainActor
@Suite("EmergencyContactsViewModel Tests")
struct EmergencyContactsViewModelTests {

    // MARK: - Helpers

    private func makeContact(
        name: String = "John Doe",
        phoneNumber: String = "+33612345678",
        relationship: EmergencyContactRelationship = .friend,
        isEnabled: Bool = true
    ) -> EmergencyContact {
        EmergencyContact(
            id: UUID(),
            name: name,
            phoneNumber: phoneNumber,
            relationship: relationship,
            isEnabled: isEnabled
        )
    }

    private func makeViewModel(
        repo: MockEmergencyContactRepository = MockEmergencyContactRepository()
    ) -> EmergencyContactsViewModel {
        EmergencyContactsViewModel(repository: repo)
    }

    // MARK: - Load

    @Test("Load fetches contacts from repository")
    func load_fetchesContacts() async {
        let repo = MockEmergencyContactRepository()
        repo.contacts = [
            makeContact(name: "Alice"),
            makeContact(name: "Bob")
        ]

        let vm = makeViewModel(repo: repo)
        await vm.load()

        #expect(vm.contacts.count == 2)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
        #expect(repo.getContactsCalled == true)
    }

    @Test("Load handles empty list")
    func load_handlesEmpty() async {
        let vm = makeViewModel()
        await vm.load()

        #expect(vm.contacts.isEmpty)
        #expect(vm.isLoading == false)
    }

    // MARK: - Save

    @Test("saveContact adds contact to list")
    func saveContact_addsContact() async {
        let repo = MockEmergencyContactRepository()
        let vm = makeViewModel(repo: repo)

        let contact = makeContact(name: "New Contact")
        await vm.saveContact(contact)

        #expect(vm.contacts.count == 1)
        #expect(vm.contacts.first?.name == "New Contact")
        #expect(repo.saveContactCalled == true)
        #expect(vm.error == nil)
    }

    @Test("saveContact handles error")
    func saveContact_handlesError() async {
        let repo = MockEmergencyContactRepository()
        repo.shouldThrow = true

        let vm = makeViewModel(repo: repo)
        await vm.saveContact(makeContact())

        #expect(vm.contacts.isEmpty)
        #expect(vm.error != nil)
    }

    // MARK: - Delete

    @Test("deleteContact removes contact at index")
    func deleteContact_removesAtIndex() {
        let repo = MockEmergencyContactRepository()
        let vm = makeViewModel(repo: repo)

        let contact1 = makeContact(name: "Alice")
        let contact2 = makeContact(name: "Bob")
        vm.contacts = [contact1, contact2]

        vm.deleteContact(at: IndexSet(integer: 0))

        #expect(vm.contacts.count == 1)
        #expect(vm.contacts.first?.name == "Bob")
    }

    @Test("deleteContact removes correct contact from middle of list")
    func deleteContact_removesCorrectContact() {
        let repo = MockEmergencyContactRepository()
        let vm = makeViewModel(repo: repo)

        let contact1 = makeContact(name: "Alice")
        let contact2 = makeContact(name: "Bob")
        let contact3 = makeContact(name: "Charlie")
        vm.contacts = [contact1, contact2, contact3]

        vm.deleteContact(at: IndexSet(integer: 1))

        #expect(vm.contacts.count == 2)
        #expect(vm.contacts[0].name == "Alice")
        #expect(vm.contacts[1].name == "Charlie")
    }

    // MARK: - Update

    @Test("updateContact updates existing contact in list")
    func updateContact_updatesExisting() async {
        let repo = MockEmergencyContactRepository()
        let vm = makeViewModel(repo: repo)

        let contact = makeContact(name: "Original Name")
        vm.contacts = [contact]

        var updated = contact
        updated.name = "Updated Name"
        await vm.updateContact(updated)

        #expect(vm.contacts.count == 1)
        #expect(vm.contacts.first?.name == "Updated Name")
        #expect(repo.updateContactCalled == true)
        #expect(vm.error == nil)
    }

    @Test("updateContact handles error")
    func updateContact_handlesError() async {
        let repo = MockEmergencyContactRepository()
        repo.shouldThrow = true

        let vm = makeViewModel(repo: repo)
        let contact = makeContact()
        vm.contacts = [contact]

        var updated = contact
        updated.name = "Should Fail"
        await vm.updateContact(updated)

        #expect(vm.error != nil)
    }

    // MARK: - Error State

    @Test("Error state is set on repository failure during load")
    func errorState_onLoadFailure() async {
        let repo = MockEmergencyContactRepository()
        repo.shouldThrow = true

        let vm = makeViewModel(repo: repo)
        await vm.load()

        #expect(vm.error != nil)
        #expect(vm.contacts.isEmpty)
        #expect(vm.isLoading == false)
    }
}
