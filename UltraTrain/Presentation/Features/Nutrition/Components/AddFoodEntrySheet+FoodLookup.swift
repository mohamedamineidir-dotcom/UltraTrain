import SwiftUI

// MARK: - Food Lookup, Search & Portion Handling

extension AddFoodEntrySheet {

    // MARK: - Quick Add Section

    @ViewBuilder
    var quickAddSection: some View {
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

    // MARK: - Portion Section

    @ViewBuilder
    var portionSection: some View {
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

    // MARK: - Portion Recalculation

    func recalculateForPortion() {
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

    // MARK: - Barcode Lookup

    @MainActor
    func lookupBarcode(_ barcode: String) async {
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

    // MARK: - Apply Search Result

    func applySearchResult(_ result: FoodSearchResult) {
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

    func saveEntry() {
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
