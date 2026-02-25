import SwiftUI

// MARK: - Scenario Cards, Confidence, Calibration, Race Day Plan & Error

extension FinishEstimationView {

    // MARK: - Scenario Cards

    func scenarioCards(_ estimate: FinishEstimate) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Predicted Finish Time")
                .font(.headline)

            HStack(spacing: Theme.Spacing.sm) {
                scenarioCard(
                    title: "Optimistic",
                    time: estimate.optimisticTime,
                    color: Theme.Colors.success
                )
                scenarioCard(
                    title: "Expected",
                    time: estimate.expectedTime,
                    color: Theme.Colors.primary
                )
                scenarioCard(
                    title: "Conservative",
                    time: estimate.conservativeTime,
                    color: Theme.Colors.warning
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    func scenarioCard(title: String, time: TimeInterval, color: Color) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(FinishEstimate.formatDuration(time))
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(AccessibilityFormatters.duration(time))")
    }

    // MARK: - Confidence

    func confidenceSection(_ estimate: FinishEstimate) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Confidence")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.0f%%", estimate.confidencePercent))
                    .font(.subheadline.bold().monospacedDigit())
            }

            ProgressView(value: estimate.confidencePercent, total: 100)
                .tint(confidenceColor(estimate.confidencePercent))

            Text(confidenceLabel(estimate.confidencePercent))
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .cardStyle()
    }

    func confidenceColor(_ percent: Double) -> Color {
        if percent >= 70 { return Theme.Colors.success }
        if percent >= 50 { return Theme.Colors.warning }
        return Theme.Colors.danger
    }

    func confidenceLabel(_ percent: Double) -> String {
        if percent >= 70 { return "Strong prediction — good training data available" }
        if percent >= 50 { return "Moderate prediction — more training data would improve accuracy" }
        return "Low confidence — keep training to improve prediction accuracy"
    }

    // MARK: - Race Calibration Badge

    func raceCalibrationBadge(estimate: FinishEstimate) -> some View {
        let count = estimate.raceResultsUsed
        let factor = estimate.calibrationFactor
        let accuracy = (1.0 - abs(1.0 - factor)) * 100

        return VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Theme.Colors.success)
                    .accessibilityHidden(true)
                Text("Calibrated from \(count) results")
                    .font(.subheadline)
            }
            if factor != 1.0 {
                Text(String(format: "Avg. accuracy: %.0f%%", accuracy))
                    .font(.caption.bold())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text(calibrationDescription(factor))
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.success.opacity(0.1))
        )
    }

    func calibrationDescription(_ factor: Double) -> String {
        if factor < 1.0 {
            return "Model adjusted down — you're faster than predicted"
        }
        return "Model adjusted up — you're slower than predicted"
    }

    // MARK: - Race Day Plan Link

    var raceDayPlanLink: some View {
        NavigationLink {
            RaceDayPlanView(
                race: race,
                finishTimeEstimator: finishTimeEstimator,
                athleteRepository: athleteRepository,
                runRepository: runRepository,
                fitnessCalculator: fitnessCalculator,
                nutritionRepository: nutritionRepository,
                nutritionGenerator: nutritionGenerator,
                raceRepository: raceRepository,
                finishEstimateRepository: finishEstimateRepository,
                weatherService: weatherService,
                locationService: locationService,
                checklistRepository: checklistRepository
            )
        } label: {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundStyle(Theme.Colors.primary)
                    .accessibilityHidden(true)
                Text("Race Day Plan")
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .accessibilityHidden(true)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.primary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Error

    func errorSection(_ message: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: errorIconSize))
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityHidden(true)
            Text(message)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Theme.Spacing.xl)
    }
}
