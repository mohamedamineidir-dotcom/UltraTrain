import SwiftUI

struct PostRaceSummaryStep: View {
    @Bindable var viewModel: PostRaceWizardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            resultCard
            pacingCard
            nutritionCard
            weatherCard
            satisfactionCard
            if viewModel.finishEstimate != nil {
                predictionComparisonCard
            }
        }
    }

    // MARK: - Result Card

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Race Result", icon: "flag.checkered")
            HStack {
                Text("Finish Time")
                    .font(.subheadline)
                Spacer()
                Text(formattedFinishTime)
                    .font(.subheadline.bold().monospacedDigit())
            }
            if let position = viewModel.actualPosition {
                HStack {
                    Text("Position")
                        .font(.subheadline)
                    Spacer()
                    Text("#" + String(position))
                        .font(.subheadline.bold())
                }
            }
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Pacing Card

    private var pacingCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Pacing", icon: "speedometer")
            Text(pacingLabel(viewModel.pacingAssessment))
                .font(.subheadline)
            if !viewModel.pacingNotes.isEmpty {
                Text(viewModel.pacingNotes)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Nutrition Card

    private var nutritionCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Nutrition", icon: "fork.knife")
            Text(nutritionLabel(viewModel.nutritionAssessment))
                .font(.subheadline)
            if viewModel.hadStomachIssues {
                Label("Stomach issues reported", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.warning)
            }
            if !viewModel.nutritionNotes.isEmpty {
                Text(viewModel.nutritionNotes)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Weather Card

    private var weatherCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Weather", icon: "cloud.sun")
            Text(weatherLabel(viewModel.weatherImpact))
                .font(.subheadline)
            if !viewModel.weatherNotes.isEmpty {
                Text(viewModel.weatherNotes)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Satisfaction Card

    private var satisfactionCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Overall", icon: "star")
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= viewModel.overallSatisfaction ? "star.fill" : "star")
                        .foregroundStyle(
                            star <= viewModel.overallSatisfaction
                                ? Theme.Colors.warning
                                : Theme.Colors.secondaryLabel
                        )
                }
            }
            if !viewModel.keyTakeaways.isEmpty {
                Text(viewModel.keyTakeaways)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .lineLimit(4)
            }
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Prediction Comparison

    private var predictionComparisonCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Actual vs Predicted", icon: "chart.bar")

            if let estimate = viewModel.finishEstimate {
                comparisonRow("Optimistic", predicted: estimate.optimisticTime)
                comparisonRow("Expected", predicted: estimate.expectedTime)
                comparisonRow("Conservative", predicted: estimate.conservativeTime)
            }
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    private func comparisonRow(_ label: String, predicted: TimeInterval) -> some View {
        let actual = viewModel.finishTimeInterval
        let diff = actual - predicted
        let diffFormatted = formatTimeDifference(diff)
        let color: Color = diff <= 0 ? Theme.Colors.success : Theme.Colors.danger

        return HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Spacer()
            Text(formatDuration(predicted))
                .font(.caption.monospacedDigit())
            Text(diffFormatted)
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(color)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
    }

    private var formattedFinishTime: String {
        let h = viewModel.finishTimeHours
        let m = viewModel.finishTimeMinutes
        let s = viewModel.finishTimeSeconds
        return String(format: "%dh%02dm%02ds", h, m, s)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return String(format: "%dh%02d", hours, minutes)
    }

    private func formatTimeDifference(_ diff: TimeInterval) -> String {
        let absDiff = abs(diff)
        let hours = Int(absDiff) / 3600
        let minutes = (Int(absDiff) % 3600) / 60
        let sign = diff <= 0 ? "-" : "+"
        if hours > 0 {
            return String(format: "(%@%dh%02d)", sign, hours, minutes)
        }
        return String(format: "(%@%dm)", sign, minutes)
    }

    private func pacingLabel(_ assessment: PacingAssessment) -> String {
        switch assessment {
        case .tooFast: return "Too Fast"
        case .tooSlow: return "Too Slow"
        case .wellPaced: return "Well Paced"
        case .mixedPacing: return "Mixed Pacing"
        }
    }

    private func nutritionLabel(_ assessment: NutritionAssessment) -> String {
        switch assessment {
        case .perfect: return "Perfect"
        case .goodEnough: return "Good Enough"
        case .someIssues: return "Some Issues"
        case .majorProblems: return "Major Problems"
        }
    }

    private func weatherLabel(_ impact: WeatherImpactLevel) -> String {
        switch impact {
        case .noImpact: return "No Impact"
        case .minor: return "Minor Impact"
        case .significant: return "Significant Impact"
        case .severe: return "Severe Impact"
        }
    }
}
