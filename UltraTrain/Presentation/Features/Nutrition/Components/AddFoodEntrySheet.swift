import SwiftUI

struct AddFoodEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMealType: MealType = .breakfast
    @State private var entryDescription: String = ""
    @State private var calories: Int = 300
    @State private var showMacros = false
    @State private var carbsGrams: Double = 0
    @State private var proteinGrams: Double = 0
    @State private var fatGrams: Double = 0
    @State private var hydrationMl: Int = 0

    let onSave: (FoodLogEntry) -> Void

    var body: some View {
        NavigationStack {
            Form {
                mealTypeSection
                descriptionSection
                caloriesSection
                macrosSection
                hydrationSection
            }
            .navigationTitle("Add Food Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("addFood.cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(entryDescription.isEmpty)
                    .accessibilityIdentifier("addFood.saveButton")
                }
            }
        }
        .accessibilityIdentifier("addFood.sheet")
    }

    // MARK: - Meal Type

    private var mealTypeSection: some View {
        Section("Meal Type") {
            Picker("Meal", selection: $selectedMealType) {
                ForEach(MealType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.icon)
                        .tag(type)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("addFood.mealTypePicker")
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        Section("Description") {
            TextField("What did you eat?", text: $entryDescription)
                .accessibilityIdentifier("addFood.descriptionField")
                .accessibilityLabel("Food description")
        }
    }

    // MARK: - Calories

    private var caloriesSection: some View {
        Section("Calories") {
            Stepper(
                "\(calories) kcal",
                value: $calories,
                in: 0...5000,
                step: 50
            )
            .accessibilityIdentifier("addFood.caloriesStepper")
            .accessibilityLabel("Calories")
            .accessibilityValue("\(calories) kilocalories")
        }
    }

    // MARK: - Macros

    private var macrosSection: some View {
        Section {
            DisclosureGroup("Macronutrients (optional)", isExpanded: $showMacros) {
                macroStepper(
                    label: "Carbs",
                    value: $carbsGrams,
                    unit: "g",
                    identifier: "addFood.carbsStepper"
                )
                macroStepper(
                    label: "Protein",
                    value: $proteinGrams,
                    unit: "g",
                    identifier: "addFood.proteinStepper"
                )
                macroStepper(
                    label: "Fat",
                    value: $fatGrams,
                    unit: "g",
                    identifier: "addFood.fatStepper"
                )
            }
        }
    }

    private func macroStepper(
        label: String,
        value: Binding<Double>,
        unit: String,
        identifier: String
    ) -> some View {
        Stepper(
            "\(label): \(Int(value.wrappedValue))\(unit)",
            value: value,
            in: 0...500,
            step: 5
        )
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(label)
        .accessibilityValue("\(Int(value.wrappedValue)) grams")
    }

    // MARK: - Hydration

    private var hydrationSection: some View {
        Section("Hydration") {
            Stepper(
                "\(hydrationMl) ml",
                value: $hydrationMl,
                in: 0...2000,
                step: 100
            )
            .accessibilityIdentifier("addFood.hydrationStepper")
            .accessibilityLabel("Hydration")
            .accessibilityValue("\(hydrationMl) milliliters")
        }
    }

    // MARK: - Save

    private func saveEntry() {
        let entry = FoodLogEntry(
            id: UUID(),
            date: Date.now,
            mealType: selectedMealType,
            description: entryDescription,
            caloriesEstimate: calories > 0 ? calories : nil,
            carbsGrams: carbsGrams > 0 ? carbsGrams : nil,
            proteinGrams: proteinGrams > 0 ? proteinGrams : nil,
            fatGrams: fatGrams > 0 ? fatGrams : nil,
            hydrationMl: hydrationMl > 0 ? hydrationMl : nil,
            productId: nil
        )
        onSave(entry)
        dismiss()
    }
}
