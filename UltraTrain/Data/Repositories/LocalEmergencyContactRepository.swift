import Foundation
import SwiftData
import os

final class LocalEmergencyContactRepository: EmergencyContactRepository, @unchecked Sendable {

    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    @MainActor
    func getContacts() async throws -> [EmergencyContact] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<EmergencyContactSwiftDataModel>(
            sortBy: [SortDescriptor(\.name)]
        )
        let models = try context.fetch(descriptor)
        return models.map(EmergencyContactSwiftDataMapper.toDomain)
    }

    @MainActor
    func getContact(id: UUID) async throws -> EmergencyContact? {
        let context = modelContainer.mainContext
        let targetId = id
        let descriptor = FetchDescriptor<EmergencyContactSwiftDataModel>(
            predicate: #Predicate { $0.contactId == targetId }
        )
        guard let model = try context.fetch(descriptor).first else { return nil }
        return EmergencyContactSwiftDataMapper.toDomain(model)
    }

    @MainActor
    func saveContact(_ contact: EmergencyContact) async throws {
        let context = modelContainer.mainContext
        let model = EmergencyContactSwiftDataMapper.toSwiftData(contact)
        context.insert(model)
        try context.save()
    }

    @MainActor
    func updateContact(_ contact: EmergencyContact) async throws {
        let context = modelContainer.mainContext
        let targetId = contact.id
        let descriptor = FetchDescriptor<EmergencyContactSwiftDataModel>(
            predicate: #Predicate { $0.contactId == targetId }
        )
        guard let existing = try context.fetch(descriptor).first else {
            throw DomainError.emergencyContactNotFound
        }
        existing.name = contact.name
        existing.phoneNumber = contact.phoneNumber
        existing.relationship = contact.relationship.rawValue
        existing.isEnabled = contact.isEnabled
        try context.save()
    }

    @MainActor
    func deleteContact(id: UUID) async throws {
        let context = modelContainer.mainContext
        let targetId = id
        let descriptor = FetchDescriptor<EmergencyContactSwiftDataModel>(
            predicate: #Predicate { $0.contactId == targetId }
        )
        guard let model = try context.fetch(descriptor).first else { return }
        context.delete(model)
        try context.save()
    }
}
