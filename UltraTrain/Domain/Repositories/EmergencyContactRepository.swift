import Foundation

protocol EmergencyContactRepository: Sendable {
    func getContacts() async throws -> [EmergencyContact]
    func getContact(id: UUID) async throws -> EmergencyContact?
    func saveContact(_ contact: EmergencyContact) async throws
    func updateContact(_ contact: EmergencyContact) async throws
    func deleteContact(id: UUID) async throws
}
