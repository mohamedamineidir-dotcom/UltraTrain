import SwiftUI

struct SessionNutritionSection: View {
    let advice: SessionNutritionAdvice

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Label("Nutrition", systemImage: "fork.knife")
                .font(.headline)

            if let preRun = advice.preRun {
                preRunCard(preRun)
            }
            if let duringRun = advice.duringRun {
                duringRunCard(duringRun)
            }
            postRunCard(advice.postRun)
        }
    }

    // MARK: - Pre-Run

    private func preRunCard(_ preRun: PreRunAdvice) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "Pre-Run", icon: "cup.and.saucer.fill", color: .orange)

            HStack(spacing: Theme.Spacing.md) {
                miniStat(label: "Timing", value: preRun.timingDescription)
                miniStat(label: "Carbs", value: "\(preRun.carbsGrams)g")
                miniStat(label: "Fluid", value: "\(preRun.hydrationMl) ml")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Meal ideas")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                ForEach(preRun.mealSuggestions, id: \.self) { meal in
                    HStack(spacing: Theme.Spacing.xs) {
                        Circle()
                            .fill(Theme.Colors.secondaryLabel)
                            .frame(width: 4, height: 4)
                            .accessibilityHidden(true)
                        Text(meal)
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
            }

            if let avoidNotes = preRun.avoidNotes {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.warning)
                        .accessibilityHidden(true)
                    Text(avoidNotes)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.warning)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Warning: \(avoidNotes)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - During-Run

    private func duringRunCard(_ duringRun: DuringRunAdvice) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                sectionHeader(title: "During Run", icon: "bolt.fill", color: .blue)
                Spacer()
                if advice.isGutTrainingRecommended {
                    GutTrainingBadge()
                }
            }

            HStack(spacing: Theme.Spacing.md) {
                miniStat(label: "Cal/h", value: "\(duringRun.caloriesPerHour)")
                miniStat(label: "Fluid/h", value: "\(duringRun.hydrationMlPerHour) ml")
                miniStat(label: "Carbs/h", value: "\(duringRun.carbsGramsPerHour)g")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Suggested products")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                ForEach(duringRun.suggestedProducts, id: \.product.id) { suggestion in
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: suggestion.product.type.icon)
                            .font(.caption)
                            .foregroundStyle(suggestion.product.type.color)
                            .frame(width: 16)
                            .accessibilityHidden(true)
                        Text(suggestion.product.name)
                            .font(.caption)
                        Spacer()
                        Text(suggestion.frequencyDescription)
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(suggestion.product.name), \(suggestion.frequencyDescription)")
                }
            }

            if let notes = duringRun.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.primary)
                    .fontWeight(.medium)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Post-Run

    private func postRunCard(_ postRun: PostRunAdvice) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                sectionHeader(title: "Post-Run", icon: "heart.circle.fill", color: .green)
                Spacer()
                priorityBadge(postRun.priority)
            }

            HStack(spacing: Theme.Spacing.md) {
                miniStat(label: "Window", value: postRun.windowDescription)
                miniStat(label: "Protein", value: "\(postRun.proteinGrams)g")
                miniStat(label: "Carbs", value: "\(postRun.carbsGrams)g")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Recovery meals")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                ForEach(postRun.mealSuggestions, id: \.self) { meal in
                    HStack(spacing: Theme.Spacing.xs) {
                        Circle()
                            .fill(Theme.Colors.secondaryLabel)
                            .frame(width: 4, height: 4)
                            .accessibilityHidden(true)
                        Text(meal)
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Components

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(title)
                .font(.subheadline.bold())
        }
    }

    private func miniStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(value)
                .font(.caption.bold())
        }
    }

    private func priorityBadge(_ priority: RecoveryPriority) -> some View {
        let (text, color): (String, Color) = switch priority {
        case .high: ("Priority", Theme.Colors.danger)
        case .moderate: ("Moderate", Theme.Colors.warning)
        case .low: ("Light", Theme.Colors.success)
        }
        return Text(text)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

}
