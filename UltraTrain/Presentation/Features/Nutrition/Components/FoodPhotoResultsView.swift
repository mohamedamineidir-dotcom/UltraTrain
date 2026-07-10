import SwiftUI

struct FoodPhotoResultsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var items: [AnalyzedFoodItem]
    let photoData: Data?
    let isAnalyzing: Bool
    let onAddItem: (AnalyzedFoodItem) -> Void
    let onAddAll: () -> Void

    @State private var showEditDetails = false
    @State private var expandedItemId: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if isAnalyzing {
                    analyzingView
                } else if items.isEmpty {
                    emptyStateView
                } else {
                    summaryView
                }
            }
            .navigationTitle(String(localized: "Food Analysis"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
            }
        }
    }

    // MARK: - Analyzing State

    private var analyzingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            if let photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                            .stroke(Theme.Colors.warmCoral.opacity(0.4), lineWidth: 2)
                    )
                    .shadow(color: Theme.Colors.warmCoral.opacity(0.25), radius: 16, y: 6)
            }

            VStack(spacing: Theme.Spacing.sm) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Theme.Colors.warmCoral)

                Text(String(localized: "Analyzing your food..."))
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(String(localized: "AI is identifying items and estimating nutrition"))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView(
            String(localized: "No Food Detected"),
            systemImage: "fork.knife.circle",
            description: Text(String(localized: "Try taking a clearer photo with better lighting."))
        )
    }

    // MARK: - Summary (photo → description → macros → confirm)

    private var summaryView: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                photoPreview

                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text(mealDescription)
                        .font(.title3.bold())
                        .fixedSize(horizontal: false, vertical: true)

                    macroGrid
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.md)
                .appCardStyle()

                editDetailsSection
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.sm)
            .padding(.bottom, 110) // room for the floating CTA below
        }
        .safeAreaInset(edge: .bottom) { confirmButton }
    }

    private var photoPreview: some View {
        Group {
            if let photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
            }
        }
    }

    private var mealDescription: String {
        items.map { $0.name }.joined(separator: ", ")
    }

    private var macroGrid: some View {
        HStack(spacing: Theme.Spacing.sm) {
            macroTile(
                value: "\(totalCalories)",
                label: String(localized: "Calories"),
                color: Theme.Colors.warmCoral
            )
            macroTile(
                value: "\(Int(totalCarbs))g",
                label: String(localized: "Carbs"),
                color: .blue
            )
            macroTile(
                value: "\(Int(totalProtein))g",
                label: String(localized: "Protein"),
                color: .green
            )
            macroTile(
                value: "\(Int(totalFat))g",
                label: String(localized: "Fat"),
                color: .orange
            )
        }
    }

    private func macroTile(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(color.opacity(0.12))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Add or Edit Details

    private var editDetailsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showEditDetails.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text(String(localized: "fph.addOrEdit", defaultValue: "Add or edit details"))
                        .font(.subheadline.weight(.medium))
                    Image(systemName: showEditDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(Theme.Colors.primary)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("foodPhoto.editDetailsToggle")

            if showEditDetails {
                VStack(spacing: Theme.Spacing.sm) {
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
                                withAnimation { items.removeAll { $0.id == item.id } }
                            }
                        )
                    }
                }
                .padding(.top, Theme.Spacing.xs)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Theme.Spacing.md)
        .appCardStyle()
    }

    // MARK: - Confirm CTA

    private var confirmButton: some View {
        Button {
            onAddAll()
        } label: {
            Text(String(localized: "fph.confirmAndTrack", defaultValue: "Confirm and Track"))
                .font(.headline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(Theme.Gradients.warmCoralCTA)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                .shadow(color: Theme.Colors.warmCoral.opacity(0.4), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
        .background(.ultraThinMaterial)
        .accessibilityIdentifier("foodPhoto.addAllButton")
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
                    Text("\(String(localized: "Carbs")): \(Int(item.carbsGrams))g · \(String(localized: "Protein")): \(Int(item.proteinGrams))g · \(String(localized: "Fat")): \(Int(item.fatGrams))g")
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
                    .accessibilityLabel(String(format: String(localized: "fph.addItem", defaultValue: "Add %@"), item.name))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onToggle() }

            // Expanded editor
            if isExpanded {
                VStack(spacing: Theme.Spacing.xs) {
                    editStepper(
                        label: String(localized: "fph.portion", defaultValue: "Portion"),
                        value: Binding(
                            get: { Int(item.portionGrams) },
                            set: { item.portionGrams = Double($0) }
                        ),
                        unit: "g",
                        range: 1...2000,
                        step: item.portionGrams < 50 ? 5 : 10
                    )
                    editStepper(
                        label: String(localized: "Calories"),
                        value: $item.calories,
                        unit: "kcal",
                        range: 0...5000,
                        step: 10
                    )
                    editStepper(
                        label: String(localized: "Carbs"),
                        value: Binding(
                            get: { Int(item.carbsGrams) },
                            set: { item.carbsGrams = Double($0) }
                        ),
                        unit: "g",
                        range: 0...500,
                        step: 5
                    )
                    editStepper(
                        label: String(localized: "Protein"),
                        value: Binding(
                            get: { Int(item.proteinGrams) },
                            set: { item.proteinGrams = Double($0) }
                        ),
                        unit: "g",
                        range: 0...500,
                        step: 5
                    )
                    editStepper(
                        label: String(localized: "Fat"),
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
