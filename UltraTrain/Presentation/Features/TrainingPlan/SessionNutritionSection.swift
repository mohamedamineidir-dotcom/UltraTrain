import SwiftUI

/// Compact nutrition card for the session detail page. Nutrition is
/// a *bonus* on the training page — useful at a glance, not the main
/// reason the athlete opened the screen. The previous version stacked
/// expandable phase rows with mini-stat grids + meal-idea
/// disclosures, which made the card almost as tall as the training
/// content itself. This version reduces each phase to a single
/// inline summary line (headline numbers only) so the card is short
/// and skimmable. Athletes who want full meal ideas / suggested
/// products go to the dedicated Nutrition tab.
struct SessionNutritionSection: View {
    let advice: SessionNutritionAdvice

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            header
            if let preRun = advice.preRun {
                phaseLine(
                    title: "Pre-Run",
                    icon: "cup.and.saucer.fill",
                    iconColor: .orange,
                    detail: "\(preRun.timingDescription) · \(preRun.carbsGrams)g carbs"
                )
            }
            if let duringRun = advice.duringRun {
                phaseLine(
                    title: "During",
                    icon: "bolt.fill",
                    iconColor: .blue,
                    detail: "\(duringRun.caloriesPerHour) cal/h · \(duringRun.hydrationMlPerHour) ml/h"
                )
            }
            phaseLine(
                title: "Post-Run",
                icon: "heart.circle.fill",
                iconColor: .green,
                detail: "\(advice.postRun.windowDescription) · \(advice.postRun.proteinGrams)g protein"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.sm + 2)
        .futuristicGlassStyle(phaseTint: Theme.Colors.warning)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "fork.knife")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.Colors.warning)
                .frame(width: 18)
            Text("Nutrition")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.Colors.warning)
            Spacer()
            if advice.isGutTrainingRecommended {
                GutTrainingBadge()
            }
        }
    }

    private func phaseLine(
        title: String,
        icon: String,
        iconColor: Color,
        detail: String
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(iconColor)
                .frame(width: 18)
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.primary)
                .frame(width: 64, alignment: .leading)
            Text(detail)
                .font(.caption.monospacedDigit())
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
        }
    }
}
