import SwiftUI

struct AddEditEmergencyContactView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var phoneNumber: String
    @State private var relationship: EmergencyContactRelationship
    @State private var isEnabled: Bool

    private let existingContact: EmergencyContact?
    private let onSave: (EmergencyContact) -> Void

    private var isEditing: Bool { existingContact != nil }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(
        contact: EmergencyContact? = nil,
        onSave: @escaping (EmergencyContact) -> Void
    ) {
        self.existingContact = contact
        self.onSave = onSave
        _name = State(initialValue: contact?.name ?? "")
        _phoneNumber = State(initialValue: contact?.phoneNumber ?? "")
        _relationship = State(initialValue: contact?.relationship ?? .friend)
        _isEnabled = State(initialValue: contact?.isEnabled ?? true)
    }

    var body: some View {
        Form {
            contactInfoSection
            relationshipSection
            statusSection
        }
        .navigationTitle(isEditing ? "Edit Contact" : "Add Contact")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(!isValid)
                .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Sections

    private var contactInfoSection: some View {
        Section {
            TextField("Name", text: $name)
                .textContentType(.name)
                .accessibilityLabel("Contact name")
                .accessibilityHint("Enter the emergency contact's full name")

            TextField("Phone Number", text: $phoneNumber)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .accessibilityLabel("Phone number")
                .accessibilityHint("Enter the emergency contact's phone number")
        } header: {
            Text("Contact Information")
        }
    }

    private var relationshipSection: some View {
        Section {
            Picker("Relationship", selection: $relationship) {
                ForEach(EmergencyContactRelationship.allCases, id: \.self) { relation in
                    Text(relation.displayName).tag(relation)
                }
            }
            .accessibilityHint("Select how this person is related to you")
        } header: {
            Text("Relationship")
        }
    }

    private var statusSection: some View {
        Section {
            Toggle("Enabled", isOn: $isEnabled)
                .accessibilityHint("When disabled, this contact will not be notified during emergencies")
        } footer: {
            Text("Disabled contacts remain saved but will not receive emergency alerts.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Actions

    private func save() {
        let contact = EmergencyContact(
            id: existingContact?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespaces),
            relationship: relationship,
            isEnabled: isEnabled
        )
        onSave(contact)
        dismiss()
    }
}
