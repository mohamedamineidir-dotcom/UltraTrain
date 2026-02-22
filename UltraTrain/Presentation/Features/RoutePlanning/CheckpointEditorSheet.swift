import SwiftUI

struct CheckpointEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var checkpoint: Checkpoint
    let onDelete: () -> Void

    @State private var name: String
    @State private var hasAidStation: Bool

    init(checkpoint: Binding<Checkpoint>, onDelete: @escaping () -> Void) {
        _checkpoint = checkpoint
        self.onDelete = onDelete
        _name = State(initialValue: checkpoint.wrappedValue.name)
        _hasAidStation = State(initialValue: checkpoint.wrappedValue.hasAidStation)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Checkpoint Details") {
                    TextField("Name", text: $name)
                    Toggle("Aid Station", isOn: $hasAidStation)
                }

                Section {
                    HStack {
                        Text("Distance from start")
                        Spacer()
                        Text(String(format: "%.1f km", checkpoint.distanceFromStartKm))
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Label("Delete Checkpoint", systemImage: "trash")
                            .foregroundStyle(Theme.Colors.danger)
                    }
                }
            }
            .navigationTitle("Edit Checkpoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        checkpoint.name = name.trimmingCharacters(in: .whitespaces)
                        checkpoint.hasAidStation = hasAidStation
                        dismiss()
                    }
                }
            }
        }
    }
}
