import SwiftUI

struct EditCheckpointSheet: View {
    let checkpoint: Checkpoint?
    let raceDistanceKm: Double
    let onSave: (Checkpoint) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var distanceKm: Double
    @State private var elevationM: Double
    @State private var hasAidStation: Bool

    private let existingId: UUID?

    init(
        checkpoint: Checkpoint? = nil,
        raceDistanceKm: Double,
        onSave: @escaping (Checkpoint) -> Void
    ) {
        self.checkpoint = checkpoint
        self.raceDistanceKm = raceDistanceKm
        self.onSave = onSave
        if let cp = checkpoint {
            existingId = cp.id
            _name = State(initialValue: cp.name)
            _distanceKm = State(initialValue: cp.distanceFromStartKm)
            _elevationM = State(initialValue: cp.elevationM)
            _hasAidStation = State(initialValue: cp.hasAidStation)
        } else {
            existingId = nil
            _name = State(initialValue: "")
            _distanceKm = State(initialValue: 10)
            _elevationM = State(initialValue: 0)
            _hasAidStation = State(initialValue: true)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Checkpoint Info") {
                    TextField("Name (e.g. Col du Bonhomme)", text: $name)
                        .autocorrectionDisabled()
                    LabeledStepper(
                        label: "Distance from start",
                        value: $distanceKm,
                        range: 1...max(1, raceDistanceKm),
                        step: 1,
                        unit: "km"
                    )
                    LabeledStepper(
                        label: "Elevation",
                        value: $elevationM,
                        range: 0...5000,
                        step: 50,
                        unit: "m"
                    )
                }

                Section {
                    Toggle("Aid Station", isOn: $hasAidStation)
                }
            }
            .navigationTitle(checkpoint == nil ? "Add Checkpoint" : "Edit Checkpoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && distanceKm > 0
    }

    private func save() {
        let cp = Checkpoint(
            id: existingId ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            distanceFromStartKm: distanceKm,
            elevationM: elevationM,
            hasAidStation: hasAidStation
        )
        onSave(cp)
        dismiss()
    }
}
