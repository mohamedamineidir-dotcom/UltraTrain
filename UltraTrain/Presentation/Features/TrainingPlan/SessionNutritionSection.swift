import SwiftUI

/// Compact nutrition card for the session detail page. The previous
/// version stacked three full cards (Pre / During / Post), each with
/// mini-stats + bulleted meal lists — too dense and confusing per
/// athlete feedback. This redesign collapses each phase into a tight
/// row with the headline numbers visible by default; meal ideas /
/// suggested products / recovery meals are tucked behind a per-phase
/// disclosure ("Show ideas") so the athlete sees ONLY what matters
/// at a glance. Wrapped in a single futuristic glass card matching
/// the rest of the session detail page.
struct SessionNutritionSection: View {
    let advice: SessionNutritionAdvice

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: 8) {
                Image(systemName: "fork.knife")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle().fill(
                            LinearGradient(
                                colors: [Theme.Colors.warning, Theme.Colors.warning.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
                    .shadow(color: Theme.Colors.warning.opacity(0.35), radius: 6, y: 2)
                Text("Nutrition")
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.Colors.warning)
                Spacer()
                if advice.isGutTrainingRecommended {
                    GutTrainingBadge()
                }
            }

            if let preRun = advice.preRun {
                phaseRow(
                    title: "Pre-Run",
                    icon: "cup.and.saucer.fill",
                    iconColor: .orange,
                    stats: [
                        ("Timing", preRun.timingDescription),
                        ("Carbs", "\(preRun.carbsGrams)g"),
                        ("Fluid", "\(preRun.hydrationMl) ml")
                    ],
                    disclosureLabel: "Meal ideas",
                    disclosureItems: preRun.mealSuggestions,
                    warning: preRun.avoidNotes,
                    trailingBadge: nil
                )
            }

            if let duringRun = advice.duringRun {
                phaseRow(
                    title: "During Run",
                    icon: "bolt.fill",
                    iconColor: .blue,
                    stats: [
                        ("Cal/h", "\(duringRun.caloriesPerHour)"),
                        ("Fluid/h", "\(duringRun.hydrationMlPerHour) ml"),
                        ("Carbs/h", "\(duringRun.carbsGramsPerHour)g")
                    ],
                    disclosureLabel: duringRun.suggestedProducts.isEmpty ? nil : "Suggested products",
                    disclosureItems: duringRun.suggestedProducts.map {
                        "\($0.product.name) — \($0.frequencyDescription)"
                    },
                    warning: duringRun.notes,
                    trailingBadge: nil
                )
            }

            phaseRow(
                title: "Post-Run",
                icon: "heart.circle.fill",
                iconColor: .green,
                stats: [
                    ("Window", advice.postRun.windowDescription),
                    ("Protein", "\(advice.postRun.proteinGrams)g"),
                    ("Carbs", "\(advice.postRun.carbsGrams)g")
                ],
                disclosureLabel: "Recovery meals",
                disclosureItems: advice.postRun.mealSuggestions,
                warning: nil,
                trailingBadge: priorityBadge(advice.postRun.priority)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: Theme.Colors.warning)
    }

    // MARK: - Phase row (collapsed by default)

    @ViewBuilder
    private func phaseRow(
        title: String,
        icon: String,
        iconColor: Color,
        stats: [(String, String)],
        disclosureLabel: String?,
        disclosureItems: [String],
        warning: String?,
        trailingBadge: AnyView?
    ) -> some View {
        PhaseRowView(
            title: title,
            icon: icon,
            iconColor: iconColor,
            stats: stats,
            disclosureLabel: disclosureLabel,
            disclosureItems: disclosureItems,
            warning: warning,
            trailingBadge: trailingBadge
        )
    }

    private func priorityBadge(_ priority: RecoveryPriority) -> AnyView {
        let (text, color): (String, Color) = switch priority {
        case .high:     ("Priority", Theme.Colors.danger)
        case .moderate: ("Moderate", Theme.Colors.warning)
        case .low:      ("Light", Theme.Colors.success)
        }
        return AnyView(
            Text(text)
                .font(.caption2.bold())
                .foregroundStyle(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(color.opacity(0.15)))
        )
    }
}

private struct PhaseRowView: View {
    let title: String
    let icon: String
    let iconColor: Color
    let stats: [(String, String)]
    let disclosureLabel: String?
    let disclosureItems: [String]
    let warning: String?
    let trailingBadge: AnyView?

    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundStyle(iconColor)
                    .frame(width: 18)
                Text(title)
                    .font(.subheadline.bold())
                Spacer()
                if let trailingBadge {
                    trailingBadge
                }
            }

            HStack(spacing: Theme.Spacing.md) {
                ForEach(stats, id: \.0) { stat in
                    VStack(alignment: .leading, spacing: 1) {
                        Text(stat.0.uppercased())
                            .font(.caption2)
                            .tracking(0.3)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                        Text(stat.1)
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(.primary)
                    }
                }
                Spacer()
            }

            if let warning {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.warning)
                    Text(warning)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.warning)
                }
            }

            if let disclosureLabel, !disclosureItems.isEmpty {
                if expanded {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(disclosureItems, id: \.self) { item in
                            HStack(alignment: .top, spacing: 6) {
                                Circle()
                                    .fill(Theme.Colors.secondaryLabel)
                                    .frame(width: 3, height: 3)
                                    .padding(.top, 7)
                                Text(item)
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.secondaryLabel)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.top, 2)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Text(expanded ? "Hide \(disclosureLabel.lowercased())" : "Show \(disclosureLabel.lowercased())")
                            .font(.caption2.bold())
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(iconColor)
                }
            }
        }
    }
}
