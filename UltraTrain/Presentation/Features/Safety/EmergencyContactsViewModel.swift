import Foundation
import os

@Observable
@MainActor
final class EmergencyContactsViewModel {
    private let repository: any EmergencyContactRepository

    var contacts: [EmergencyContact] = []
    var isLoading = false
    var error: String?
    var showAddContact = false
    var editingContact: EmergencyContact?

    init(repository: any EmergencyContactRepository) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            contacts = try await repository.getContacts()
        } catch {
            self.error = error.localizedDescription
            Logger.safety.error("Failed to load emergency contacts: \(error)")
        }
        isLoading = false
    }

    func saveContact(_ contact: EmergencyContact) async {
        do {
            try await repository.saveContact(contact)
            contacts.append(contact)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateContact(_ contact: EmergencyContact) async {
        do {
            try await repository.updateContact(contact)
            if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
                contacts[index] = contact
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteContact(at offsets: IndexSet) {
        let toDelete = offsets.map { contacts[$0] }
        for contact in toDelete {
            Task {
                do {
                    try await repository.deleteContact(id: contact.id)
                } catch {
                    self.error = error.localizedDescription
                }
            }
        }
        contacts.remove(atOffsets: offsets)
    }
}
