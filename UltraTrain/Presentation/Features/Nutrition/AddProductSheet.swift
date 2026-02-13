import SwiftUI

struct AddProductSheet: View {
    @Bindable var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var type: ProductType = .gel
    @State private var calories: Int = 100
    @State private var carbs: Double = 25.0
    @State private var sodium: Int = 50
    @State private var caffeinated = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Product Info") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(ProductType.allCases, id: \.self) { productType in
                            Text(productType.displayName).tag(productType)
                        }
                    }
                }

                Section("Nutrition per Serving") {
                    LabeledIntStepper(label: "Calories", value: $calories, range: 0...500, unit: "kcal")
                    LabeledStepper(label: "Carbs", value: $carbs, range: 0...100, step: 1.0, unit: "g")
                    LabeledIntStepper(label: "Sodium", value: $sodium, range: 0...1000, unit: "mg")
                    Toggle("Caffeinated", isOn: $caffeinated)
                }
            }
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let product = NutritionProduct(
                            id: UUID(),
                            name: name,
                            type: type,
                            caloriesPerServing: calories,
                            carbsGramsPerServing: carbs,
                            sodiumMgPerServing: sodium,
                            caffeinated: caffeinated
                        )
                        Task {
                            await viewModel.addProduct(product)
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
