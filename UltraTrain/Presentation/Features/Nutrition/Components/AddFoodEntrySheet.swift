import SwiftUI

struct AddFoodEntrySheet: View {
    @Environment(\.dismiss) var dismiss

    @State var selectedMealType: MealType = .breakfast
    @State var entryDescription: String = ""
    @State var calories: Int = 300
    @State var showMacros = false
    @State var carbsGrams: Double = 0
    @State var proteinGrams: Double = 0
    @State var fatGrams: Double = 0
    @State var hydrationMl: Int = 0
    @State var showingBarcodeScanner = false
    @State var showingFoodSearch = false
    @State var isLookingUp = false
    @State var lookupError: String?
    @State var portionGrams: Double = 100
    @State var basePer100g: (cal: Int?, carbs: Double?, protein: Double?, fat: Double?) = (nil, nil, nil, nil)
    @State var selectedFoodResultId: String?

    // Food Photo AI
    @State var showingFoodPhotoCamera = false
    @State var showingPhotoResults = false
    @State var capturedPhotoData: Data?
    @State var analyzedItems: [AnalyzedFoodItem] = []
    @State var isAnalyzing = false

    let foodDatabaseService: (any FoodDatabaseServiceProtocol)?
    let foodPhotoAnalysisService: (any FoodPhotoAnalysisServiceProtocol)?
    let onSave: (FoodLogEntry) -> Void

    init(
        foodDatabaseService: (any FoodDatabaseServiceProtocol)? = nil,
        foodPhotoAnalysisService: (any FoodPhotoAnalysisServiceProtocol)? = nil,
        onSave: @escaping (FoodLogEntry) -> Void
    ) {
        self.foodDatabaseService = foodDatabaseService
        self.foodPhotoAnalysisService = foodPhotoAnalysisService
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
            .fullScreenCover(isPresented: $showingFoodPhotoCamera) {
                FoodPhotoCameraView { photoData in
                    showingFoodPhotoCamera = false
                    capturedPhotoData = photoData
                    Task { await analyzePhoto(photoData) }
                }
            }
            .sheet(isPresented: $showingPhotoResults) {
                FoodPhotoResultsView(
                    items: $analyzedItems,
                    photoData: capturedPhotoData,
                    isAnalyzing: isAnalyzing,
                    onAddItem: { item in
                        addAnalyzedItem(item)
                    },
                    onAddAll: {
                        for item in analyzedItems {
                            addAnalyzedItem(item)
                        }
                        dismiss()
                    }
                )
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
}
