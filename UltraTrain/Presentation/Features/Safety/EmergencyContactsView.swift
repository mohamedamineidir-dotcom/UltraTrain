import SwiftUI

struct EmergencyContactsView: View {
    @State private var viewModel: EmergencyContactsViewModel

    init(repository: any EmergencyContactRepository) {
        _viewModel = State(initialValue: EmergencyContactsViewModel(
            repository: repository
        ))
    }

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
            } else if viewModel.contacts.isEmpty {
                emptyStateView
                    .listRowSeparator(.hidden)
            } else {
                contactsSection
            }
        }
        .navigationTitle("Emergency Contacts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showAddContact = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Contact")
                .accessibilityHint("Opens a form to add a new emergency contact")
            }
        }
        .task {
            await viewModel.load()
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .sheet(isPresented: $viewModel.showAddContact) {
            NavigationStack {
                AddEditEmergencyContactView { contact in
                    Task { await viewModel.saveContact(contact) }
                }
            }
        }
        .sheet(item: $viewModel.editingContact) { contact in
            NavigationStack {
                AddEditEmergencyContactView(contact: contact) { updated in
                    Task { await viewModel.updateContact(updated) }
                }
            }
        }
    }

    // MARK: - Contacts Section

    private var contactsSection: some View {
        Section {
            ForEach(viewModel.contacts) { contact in
                contactRow(contact)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.editingContact = contact
                    }
            }
            .onDelete(perform: viewModel.deleteContact)
        } footer: {
            Text("These contacts will be notified in case of an emergency during your runs.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Contact Row

    private func contactRow(_ contact: EmergencyContact) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            contactIcon(for: contact)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(contact.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.Colors.label)
                Text(contact.phoneNumber)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text(contact.relationship.displayName)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.primary)
            }
            Spacer()
            if !contact.isEnabled {
                Text("Disabled")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(Theme.Colors.secondaryBackground)
                    )
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(contact.name), \(contact.relationship.displayName), \(contact.phoneNumber)")
        .accessibilityHint(contact.isEnabled ? "Enabled. Tap to edit." : "Disabled. Tap to edit.")
    }

    // MARK: - Contact Icon

    private func contactIcon(for contact: EmergencyContact) -> some View {
        Image(systemName: iconName(for: contact.relationship))
            .font(.title3)
            .foregroundStyle(contact.isEnabled ? Theme.Colors.danger : Theme.Colors.secondaryLabel)
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(contact.isEnabled ? Theme.Colors.danger.opacity(0.12) : Theme.Colors.secondaryBackground)
            )
            .accessibilityHidden(true)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Emergency Contacts",
            systemImage: "person.crop.circle.badge.plus",
            description: Text("Add contacts who should be notified in case of an emergency during your runs.")
        )
    }

    // MARK: - Helpers

    private func iconName(for relationship: EmergencyContactRelationship) -> String {
        switch relationship {
        case .spouse, .partner: return "heart.fill"
        case .parent: return "figure.and.child.holdinghands"
        case .sibling: return "person.2.fill"
        case .friend: return "person.fill"
        case .coach: return "figure.run"
        case .crewMember: return "person.3.fill"
        case .other: return "person.crop.circle"
        }
    }
}
