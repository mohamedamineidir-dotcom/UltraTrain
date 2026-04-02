import SwiftUI

struct FoodPhotoResultsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var items: [AnalyzedFoodItem]
    let photoData: Data?
    let isAnalyzing: Bool
    let onAddItem: (AnalyzedFoodItem) -> Void
    let onAddAll: () -> Void

    @State private var expandedItemId: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if isAnalyzing {
                    analyzingView
                } else if items.isEmpty {
                    emptyStateView
                } else {
                    resultsList
                }
            }
            .navigationTitle("Food Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Analyzing State

    private var analyzingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            if let photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                    .padding(.horizontal, Theme.Spacing.lg)
            }

            ProgressView()
                .controlSize(.large)

            Text("Analyzing your food...")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("AI is identifying items and estimating nutrition")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Food Detected",
            systemImage: "fork.knife.circle",
            description: Text("Try taking a clearer photo with better lighting.")
        )
    }

    // MARK: - Results List

    private var resultsList: some View {
        List {
            photoSection
            itemsSection
            totalSection
            addAllSection
        }
    }

    // MARK: - Photo Preview

    private var photoSection: some View {
        Section {
            if let photoData, let uiImage = UIImage(data: photoData) {
                HStack {
                    Spacer()
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 150)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
    }

    // MARK: - Food Items

    private var itemsSection: some View {
        Section("Detected Items (\(items.count))") {
            ForEach($items) { $item in
                FoodItemRow(
                    item: $item,
                    isExpanded: expandedItemId == item.id,
                    onToggle: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedItemId = expandedItemId == item.id ? nil : item.id
                        }
                    },
                    onAdd: {
                        onAddItem(item)
                        withAnimation {
                            items.removeAll { $0.id == item.id }
                        }
                    }
                )
            }
        }
    }

    // MARK: - Totals

    private var totalSection: some View {
        Section("Total") {
            HStack {
                Label("\(totalCalories) kcal", systemImage: "flame.fill")
                    .foregroundStyle(Theme.Colors.warmCoral)
                Spacer()
                Text("C: \(Int(totalCarbs))g")
                    .foregroundStyle(.secondary)
                Text("P: \(Int(totalProtein))g")
                    .foregroundStyle(.secondary)
                Text("F: \(Int(totalFat))g")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline.bold())
        }
    }

    // MARK: - Add All

    private var addAllSection: some View {
        Section {
            Button {
                onAddAll()
            } label: {
                Label("Add All Items", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("foodPhoto.addAllButton")
        }
    }

    // MARK: - Computed Totals

    private var totalCalories: Int { items.reduce(0) { $0 + $1.calories } }
    private var totalCarbs: Double { items.reduce(0) { $0 + $1.carbsGrams } }
    private var totalProtein: Double { items.reduce(0) { $0 + $1.proteinGrams } }
    private var totalFat: Double { items.reduce(0) { $0 + $1.fatGrams } }
}

// MARK: - Food Item Row

private struct FoodItemRow: View {
    @Binding var item: AnalyzedFoodItem
    let isExpanded: Bool
    let onToggle: () -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Main row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline.bold())
                    Text("\(Int(item.portionGrams))g · \(item.calories) kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("C: \(Int(item.carbsGrams))g · P: \(Int(item.proteinGrams))g · F: \(Int(item.fatGrams))g")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                HStack(spacing: Theme.Spacing.sm) {
                    Button {
                        onToggle()
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "pencil")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.warmCoral)
                    }
                    .buttonStyle(.plain)

                    Button {
                        onAdd()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.Colors.warmCoral)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add \(item.name)")
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onToggle() }

            // Expanded editor
            if isExpanded {
                VStack(spacing: Theme.Spacing.xs) {
                    editStepper(
                        label: "Portion",
                        value: Binding(
                            get: { Int(item.portionGrams) },
                            set: { item.portionGrams = Double($0) }
                        ),
                        unit: "g",
                        range: 1...2000,
                        step: item.portionGrams < 50 ? 5 : 10
                    )
                    editStepper(
                        label: "Calories",
                        value: $item.calories,
                        unit: "kcal",
                        range: 0...5000,
                        step: 10
                    )
                    editStepper(
                        label: "Carbs",
                        value: Binding(
                            get: { Int(item.carbsGrams) },
                            set: { item.carbsGrams = Double($0) }
                        ),
                        unit: "g",
                        range: 0...500,
                        step: 5
                    )
                    editStepper(
                        label: "Protein",
                        value: Binding(
                            get: { Int(item.proteinGrams) },
                            set: { item.proteinGrams = Double($0) }
                        ),
                        unit: "g",
                        range: 0...500,
                        step: 5
                    )
                    editStepper(
                        label: "Fat",
                        value: Binding(
                            get: { Int(item.fatGrams) },
                            set: { item.fatGrams = Double($0) }
                        ),
                        unit: "g",
                        range: 0...500,
                        step: 5
                    )
                }
                .padding(.top, Theme.Spacing.xs)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func editStepper(
        label: String,
        value: Binding<Int>,
        unit: String,
        range: ClosedRange<Int>,
        step: Int
    ) -> some View {
        Stepper(
            "\(label): \(value.wrappedValue)\(unit)",
            value: value,
            in: range,
            step: step
        )
        .font(.caption)
    }
}
