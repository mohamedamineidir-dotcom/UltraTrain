import SwiftUI

/// Result sheet shown after a fitness test is completed and the
/// recalibration pipeline runs. Surfaces the measured VMA, delta vs
/// baseline, and the system's recommendation in plain language.
///
/// Driven by `TrainingPlanViewModel.fitnessTestRecommendation`
/// presented via `.sheet(item:)` when non-nil.
struct FitnessTestResultBanner: View {
    let recommendation: TrainingPlanViewModel.FitnessTestRecommendation
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    headerIcon
                    titleSection
                    measurementCard
                    recommendationCard
                    Spacer(minLength: Theme.Spacing.xl)
                }
                .padding(Theme.Spacing.lg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Got it") {
                        onDismiss()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Header

    private var headerIcon: some View {
        Image(systemName: iconName)
            .font(.system(size: 36))
            .foregroundStyle(.white)
            .frame(width: 72, height: 72)
            .background(Circle().fill(iconGradient))
            .shadow(color: iconColor.opacity(0.3), radius: 8, y: 4)
            .padding(.top, Theme.Spacing.md)
    }

    private var iconName: String {
        switch recommendation.outcome.recommendation {
        case .recalibrateAll, .recalibrateTrainingPacesOnly:
            return recommendation.outcome.deltaPercent >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill"
        case .regressionPendingRetest:
            return "questionmark.circle.fill"
        case .noChange:
            return "checkmark.circle.fill"
        case .suspicious:
            return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch recommendation.outcome.recommendation {
        case .recalibrateAll, .recalibrateTrainingPacesOnly:
            return recommendation.outcome.deltaPercent >= 0 ? Theme.Colors.success : Theme.Colors.warning
        case .regressionPendingRetest:
            return Theme.Colors.warmCoral
        case .noChange:
            return Theme.Colors.success
        case .suspicious:
            return Theme.Colors.warning
        }
    }

    private var iconGradient: LinearGradient {
        LinearGradient(
            colors: [iconColor, iconColor.opacity(0.7)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(titleText)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(recommendation.variant.displayName)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    private var titleText: String {
        switch recommendation.outcome.recommendation {
        case .recalibrateAll:
            return recommendation.outcome.deltaPercent >= 0
                ? "Big jump in fitness, paces updated"
                : "Fitness shifted, paces updated"
        case .recalibrateTrainingPacesOnly:
            return "Training paces refreshed"
        case .regressionPendingRetest:
            return "Was that a tough day?"
        case .noChange:
            return "Right on track"
        case .suspicious:
            return "Result looks unusual"
        }
    }

    // MARK: - Measurement card

    @ViewBuilder
    private var measurementCard: some View {
        if let measured = recommendation.outcome.measuredVmaKmh {
            VStack(spacing: Theme.Spacing.md) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.lg) {
                    measurementColumn(
                        label: "Your test",
                        value: String(format: "%.1f km/h", measured),
                        emphasis: true
                    )
                    if let baseline = recommendation.outcome.baselineVmaKmh {
                        Divider()
                            .frame(height: 36)
                        measurementColumn(
                            label: "Previous",
                            value: String(format: "%.1f km/h", baseline),
                            emphasis: false
                        )
                    }
                }

                if recommendation.outcome.baselineVmaKmh != nil {
                    let pct = recommendation.outcome.deltaPercent * 100
                    let sign = pct >= 0 ? "+" : ""
                    Text("\(sign)\(String(format: "%.1f", pct))% vs your previous fitness anchor")
                        .font(.caption)
                        .foregroundStyle(iconColor)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.secondaryBackground)
            )
        }
    }

    private func measurementColumn(label: String, value: String, emphasis: Bool) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.tertiaryLabel)
                .textCase(.uppercase)
            Text(value)
                .font(emphasis ? .title2.monospacedDigit().bold() : .body.monospacedDigit())
                .foregroundStyle(emphasis ? Theme.Colors.label : Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Recommendation card

    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("What we're doing")
                .font(.headline)
            Text(recommendationCopy)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(iconColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(iconColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var recommendationCopy: String {
        switch recommendation.outcome.recommendation {
        case .recalibrateAll:
            if recommendation.outcome.deltaPercent >= 0 {
                return "Your training paces and race-day target have been refreshed to match your new fitness. Look at remaining sessions for the updated targets, a notification flags any goal adjustment we suggest based on the new fitness."
            } else {
                return "Your training paces have been refreshed to match where you're running today, and we've flagged a potential race-target adjustment based on the change."
            }
        case .recalibrateTrainingPacesOnly:
            return "Training paces on remaining sessions have been refreshed to match your current fitness. Race-day target stays as it was, too late in the prep to safely change it from one data point."
        case .regressionPendingRetest:
            return "That result was off your usual fitness, could be heat, sleep, life stress, or just a bad day. We've adjusted your training paces so workouts match how you're running right now, but kept your race goal. Next week you'll see a re-test in place of one intervals session, let's confirm before deciding the goal needs to change."
        case .noChange(let reason):
            return reason
        case .suspicious:
            return "The delta from your previous fitness is unusually large. Could be a measurement issue (track length wrong, GPS error, illness brewing). We didn't auto-update anything. If you're confident in the result, you can manually update your VMA in your profile."
        }
    }
}
