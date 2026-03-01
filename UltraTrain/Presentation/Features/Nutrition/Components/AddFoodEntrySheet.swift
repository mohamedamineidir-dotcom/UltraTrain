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
    @State private var showingBarcodeScanner = false
    @State private var showingFoodSearch = false
    @State private var isLookingUp = false
    @State private var lookupError: String?
    @State private var portionGrams: Double = 100
    @State private var basePer100g: (cal: Int?, carbs: Double?, protein: Double?, fat: Double?) = (nil, nil, nil, nil)
    @State private var selectedFoodResultId: String?

    let foodDatabaseService: (any FoodDatabaseServiceProtocol)?
    let onSave: (FoodLogEntry) -> Void

    init(
        foodDatabaseService: (any FoodDatabaseServiceProtocol)? = nil,
        onSave: @escaping (FoodLogEntry) -> Void
    ) {
        self.foodDatabaseService = foodDatabaseService
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                quickAddSection
                mealTypeSection
                descriptionSection
                portionSection
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
            .overlay {
                if isLookingUp {
                    ProgressView("Looking up product...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView { barcode in
                    showingBarcodeScanner = false
                    Task { await lookupBarcode(barcode) }
                }
            }
            .sheet(isPresented: $showingFoodSearch) {
                if let service = foodDatabaseService {
                    FoodSearchSheet(foodService: service) { result in
                        applySearchResult(result)
                    }
                }
            }
            .alert("Lookup Failed", isPresented: .init(
                get: { lookupError != nil },
                set: { if !$0 { lookupError = nil } }
            )) {
                Button("OK") { lookupError = nil }
            } message: {
                Text(lookupError ?? "")
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

    // MARK: - Portion Size

    @ViewBuilder
    private var portionSection: some View {
        if selectedFoodResultId != nil {
            Section("Portion Size") {
                Stepper(
                    "\(Int(portionGrams))g",
                    value: $portionGrams,
                    in: 1...2000,
                    step: portionGrams < 50 ? 5 : 10
                )
                .accessibilityIdentifier("addFood.portionStepper")
                .accessibilityLabel("Portion size")
                .accessibilityValue("\(Int(portionGrams)) grams")
                .onChange(of: portionGrams) { _, _ in
                    recalculateForPortion()
                }

                if basePer100g.cal != nil {
                    Text("Macros auto-calculated from per-100g values")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func recalculateForPortion() {
        let factor = portionGrams / 100.0
        if let cal = basePer100g.cal {
            calories = Int(Double(cal) * factor)
        }
        if let carbs = basePer100g.carbs {
            carbsGrams = (carbs * factor * 10).rounded() / 10
        }
        if let protein = basePer100g.protein {
            proteinGrams = (protein * factor * 10).rounded() / 10
        }
        if let fat = basePer100g.fat {
            fatGrams = (fat * factor * 10).rounded() / 10
        }
    }

    // MARK: - Quick Add

    @ViewBuilder
    private var quickAddSection: some View {
        if foodDatabaseService != nil {
            Section("Quick Add") {
                Button {
                    showingBarcodeScanner = true
                } label: {
                    Label("Scan Barcode", systemImage: "barcode.viewfinder")
                }
                .accessibilityIdentifier("addFood.scanBarcodeButton")

                Button {
                    showingFoodSearch = true
                } label: {
                    Label("Search Food Database", systemImage: "magnifyingglass")
                }
                .accessibilityIdentifier("addFood.searchFoodButton")
            }
        }
    }

    // MARK: - Food Lookup

    @MainActor
    private func lookupBarcode(_ barcode: String) async {
        guard let service = foodDatabaseService else { return }
        isLookingUp = true
        defer { isLookingUp = false }
        do {
            if let result = try await service.searchByBarcode(barcode) {
                applySearchResult(result)
            } else {
                lookupError = "Product not found for barcode \(barcode)"
            }
        } catch {
            lookupError = "Could not look up barcode: \(error.localizedDescription)"
        }
    }

    private func applySearchResult(_ result: FoodSearchResult) {
        if let brand = result.brand, !brand.isEmpty {
            entryDescription = "\(result.name) (\(brand))"
        } else {
            entryDescription = result.name
        }

        selectedFoodResultId = result.id
        basePer100g = (
            cal: result.caloriesPer100g,
            carbs: result.carbsPer100g,
            protein: result.proteinPer100g,
            fat: result.fatPer100g
        )

        if let serving = result.servingSizeGrams, serving > 0 {
            portionGrams = serving
        } else {
            portionGrams = 100
        }

        recalculateForPortion()

        if basePer100g.carbs != nil || basePer100g.protein != nil || basePer100g.fat != nil {
            showMacros = true
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
            productId: nil,
            portionGrams: selectedFoodResultId != nil ? portionGrams : nil,
            foodSearchResultId: selectedFoodResultId
        )
        onSave(entry)
        dismiss()
    }
}
