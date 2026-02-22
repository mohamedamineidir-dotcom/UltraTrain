import SwiftUI

struct EditGearSheet: View {
    enum Mode {
        case add
        case edit(GearItem)
    }

    let mode: Mode
    let onSave: (GearItem) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var brand: String
    @State private var type: GearType
    @State private var purchaseDate: Date
    @State private var maxDistanceKm: Double
    @State private var notes: String

    private let existingItem: GearItem?

    init(mode: Mode, onSave: @escaping (GearItem) -> Void) {
        self.mode = mode
        self.onSave = onSave

        switch mode {
        case .add:
            existingItem = nil
            _name = State(initialValue: "")
            _brand = State(initialValue: "")
            _type = State(initialValue: .trailShoes)
            _purchaseDate = State(initialValue: Date())
            _maxDistanceKm = State(initialValue: 800)
            _notes = State(initialValue: "")
        case .edit(let item):
            existingItem = item
            _name = State(initialValue: item.name)
            _brand = State(initialValue: item.brand)
            _type = State(initialValue: item.type)
            _purchaseDate = State(initialValue: item.purchaseDate)
            _maxDistanceKm = State(initialValue: item.maxDistanceKm)
            _notes = State(initialValue: item.notes ?? "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                        .accessibilityIdentifier("gear.nameField")
                    TextField("Brand", text: $brand)
                        .accessibilityIdentifier("gear.brandField")
                    Picker("Type", selection: $type) {
                        ForEach(GearType.allCases, id: \.self) { gearType in
                            Text(gearType.displayName).tag(gearType)
                        }
                    }
                }

                Section("Lifespan") {
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    HStack {
                        Text("Max Distance")
                        Spacer()
                        TextField("km", value: $maxDistanceKm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("km")
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Gear" : "Add Gear")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("gear.cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityIdentifier("gear.saveButton")
                }
            }
        }
    }

    private var isEditing: Bool {
        existingItem != nil
    }

    private func save() {
        let item = GearItem(
            id: existingItem?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            brand: brand.trimmingCharacters(in: .whitespaces),
            type: type,
            purchaseDate: purchaseDate,
            maxDistanceKm: maxDistanceKm,
            totalDistanceKm: existingItem?.totalDistanceKm ?? 0,
            totalDuration: existingItem?.totalDuration ?? 0,
            isRetired: existingItem?.isRetired ?? false,
            notes: notes.isEmpty ? nil : notes
        )
        onSave(item)
        dismiss()
    }
}

extension GearType {
    var displayName: String {
        switch self {
        case .trailShoes: "Trail Shoes"
        case .roadShoes: "Road Shoes"
        case .poles: "Poles"
        case .vest: "Vest / Pack"
        case .headlamp: "Headlamp"
        case .other: "Other"
        }
    }
}
