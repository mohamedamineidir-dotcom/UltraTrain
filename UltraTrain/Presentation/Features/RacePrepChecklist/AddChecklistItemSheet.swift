import SwiftUI

struct AddChecklistItemSheet: View {
    let onAdd: (String, ChecklistCategory, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var category: ChecklistCategory = .gear
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Name", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(ChecklistCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                }

                Section("Notes (Optional)") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(name, category, notes.isEmpty ? nil : notes)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - ChecklistCategory Display

extension ChecklistCategory {
    var displayName: String {
        switch self {
        case .gear: return "Gear"
        case .nutrition: return "Nutrition"
        case .clothing: return "Clothing"
        case .safety: return "Safety"
        case .logistics: return "Logistics"
        case .dropBag: return "Drop Bag"
        }
    }

    var icon: String {
        switch self {
        case .gear: return "backpack.fill"
        case .nutrition: return "fork.knife"
        case .clothing: return "tshirt.fill"
        case .safety: return "cross.case.fill"
        case .logistics: return "car.fill"
        case .dropBag: return "bag.fill"
        }
    }
}
