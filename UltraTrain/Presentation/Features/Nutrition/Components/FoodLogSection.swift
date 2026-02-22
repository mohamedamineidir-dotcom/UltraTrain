import SwiftUI

struct FoodLogSection: View {
    let entries: [FoodLogEntry]
    let onDelete: (UUID) -> Void
    let onAddTapped: () -> Void

    private var groupedEntries: [(MealType, [FoodLogEntry])] {
        let grouped = Dictionary(grouping: entries, by: \.mealType)
        return MealType.allCases.compactMap { mealType in
            guard let items = grouped[mealType], !items.isEmpty else { return nil }
            return (mealType, items)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Label("Food Log", systemImage: "list.clipboard")
                    .font(.headline)
                Spacer()
                Button {
                    onAddTapped()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.Colors.primary)
                }
                .accessibilityIdentifier("nutrition.addFoodEntry")
                .accessibilityLabel("Add food entry")
                .accessibilityHint("Opens form to log a meal")
            }

            if entries.isEmpty {
                emptyLogMessage
            } else {
                logEntryList
            }
        }
        .cardStyle()
        .accessibilityIdentifier("nutrition.foodLogSection")
    }

    // MARK: - Empty State

    private var emptyLogMessage: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "fork.knife.circle")
                .font(.largeTitle)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityHidden(true)
            Text("No meals logged today")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text("Tap + to start tracking your nutrition")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
    }

    // MARK: - Entry List

    private var logEntryList: some View {
        ForEach(groupedEntries, id: \.0) { mealType, items in
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(mealType.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .padding(.top, Theme.Spacing.xs)

                ForEach(items) { entry in
                    foodEntryRow(entry)
                }
            }
        }
    }

    private func foodEntryRow(_ entry: FoodLogEntry) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: entry.mealType.icon)
                .font(.caption)
                .foregroundStyle(entry.mealType.color)
                .frame(width: 20)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.description)
                    .font(.subheadline)
                    .lineLimit(1)
                if let hydration = entry.hydrationMl, hydration > 0 {
                    Text("\(hydration) ml")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.info)
                }
            }

            Spacer()

            if let calories = entry.caloriesEstimate {
                Text("\(calories) kcal")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Button(role: .destructive) {
                onDelete(entry.id)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.danger)
            }
            .accessibilityLabel("Delete \(entry.description)")
        }
        .padding(.vertical, Theme.Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - MealType Display Extensions

extension MealType {
    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .preRun: return "Pre-Run"
        case .duringRun: return "During Run"
        case .postRun: return "Post-Run"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .preRun: return "figure.run.circle"
        case .duringRun: return "bolt.fill"
        case .postRun: return "heart.circle.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "leaf.fill"
        }
    }

    var color: Color {
        switch self {
        case .breakfast: return .orange
        case .preRun: return .blue
        case .duringRun: return .yellow
        case .postRun: return .green
        case .lunch: return .red
        case .dinner: return .purple
        case .snack: return .mint
        }
    }
}
