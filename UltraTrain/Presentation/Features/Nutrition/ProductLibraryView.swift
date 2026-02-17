import SwiftUI

struct ProductLibraryView: View {
    @Bindable var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss

    private var groupedProducts: [(type: ProductType, products: [NutritionProduct])] {
        let grouped = Dictionary(grouping: viewModel.products) { $0.type }
        return ProductType.allCases.compactMap { type in
            guard let products = grouped[type], !products.isEmpty else { return nil }
            return (type: type, products: products)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Preferences") {
                    Toggle("Avoid Caffeine", isOn: Binding(
                        get: { viewModel.preferences.avoidCaffeine },
                        set: { newValue in
                            viewModel.preferences.avoidCaffeine = newValue
                            Task { await viewModel.savePreferences() }
                        }
                    ))
                    Toggle("Prefer Real Food", isOn: Binding(
                        get: { viewModel.preferences.preferRealFood },
                        set: { newValue in
                            viewModel.preferences.preferRealFood = newValue
                            Task { await viewModel.savePreferences() }
                        }
                    ))
                }

                ForEach(groupedProducts, id: \.type) { group in
                    Section(group.type.displayName) {
                        ForEach(group.products) { product in
                            productRow(product)
                        }
                    }
                }
            }
            .navigationTitle("Product Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingAddProduct = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddProduct) {
                AddProductSheet(viewModel: viewModel)
            }
        }
    }

    private func productRow(_ product: NutritionProduct) -> some View {
        let excluded = viewModel.isProductExcluded(product.id)
        return HStack {
            Image(systemName: product.type.icon)
                .foregroundStyle(excluded ? Theme.Colors.secondaryLabel : product.type.color)
            VStack(alignment: .leading) {
                Text(product.name)
                    .font(.subheadline)
                    .strikethrough(excluded)
                    .foregroundStyle(excluded ? Theme.Colors.secondaryLabel : Theme.Colors.label)
                HStack(spacing: Theme.Spacing.sm) {
                    Text("\(product.caloriesPerServing) kcal")
                    Text("\(product.carbsGramsPerServing, specifier: "%.0f")g carbs")
                    Text("\(product.sodiumMgPerServing) mg Na")
                }
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
            if product.caffeinated {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.warning)
            }
            Button {
                Task { await viewModel.toggleProductExclusion(product.id) }
            } label: {
                Image(systemName: excluded ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(excluded ? .red : .green)
            }
            .buttonStyle(.plain)
        }
    }
}
