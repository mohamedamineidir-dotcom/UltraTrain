import SwiftUI

// MARK: - Scenario Cards, Confidence, Calibration & Error

extension FinishEstimationView {

    // MARK: - Scenario Cards

    func scenarioCards(_ estimate: FinishEstimate) -> some View {
        NavigationLink {
            FinishTimeEvolutionView(
                race: race,
                estimate: estimate,
                experience: viewModel.athleteExperience
            )
        } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: 6) {
                    Text("Predicted Finish Time")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.Colors.primary)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.Colors.tertiaryLabel)
                }

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

                Text("Tap to see how this evolves with your prep →")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
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

    // MARK: - Data Source Badge

    /// Inline indicator that explains where the prediction came from
    /// (PB-based / runs-derived / generic-fallback). The athlete sees
    /// the range narrow + this badge change as they accumulate data.
    func dataSourceBadge(source: FinishPredictionSource) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: dataSourceIcon(source))
                .foregroundStyle(dataSourceColor(source))
                .font(.subheadline)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(source.shortLabel)
                    .font(.caption.bold())
                    .foregroundStyle(dataSourceColor(source))
                Text(source.explainer)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(dataSourceColor(source).opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .stroke(dataSourceColor(source).opacity(0.3), lineWidth: 1)
        )
    }

    private func dataSourceIcon(_ source: FinishPredictionSource) -> String {
        switch source {
        case .runs:               return "checkmark.circle.fill"
        case .personalBests:      return "info.circle.fill"
        case .experienceFallback: return "questionmark.circle.fill"
        }
    }

    private func dataSourceColor(_ source: FinishPredictionSource) -> Color {
        switch source {
        case .runs:               return Theme.Colors.success
        case .personalBests:      return Theme.Colors.warmCoral
        case .experienceFallback: return Theme.Colors.warning
        }
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
