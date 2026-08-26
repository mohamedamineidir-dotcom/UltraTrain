import SwiftUI

// MARK: - Scenario Cards, Confidence, Calibration & Error

extension FinishEstimationView {

    // MARK: - Scenario Cards

    /// Whether the predicted-time evolution chart is meaningful for this
    /// race. The chart projects an improvement curve across the prep
    /// window, which doesn't say anything useful when there's less than
    /// 4 weeks of training between today and the race AND the race isn't
    /// the A-race. B/C races scheduled in the first few weeks of a prep
    /// can't show real adaptation, so we hide the chart entirely instead
    /// of drawing a curve the athlete shouldn't trust.
    private var showsEvolutionChart: Bool {
        if viewModel.race.priority == .aRace { return true }
        let weeksToRace = max(0, Int((viewModel.race.date.timeIntervalSinceNow / 86400 / 7).rounded()))
        return weeksToRace >= 4
    }

    @ViewBuilder
    func scenarioCards(_ estimate: FinishEstimate) -> some View {
        if showsEvolutionChart {
            NavigationLink {
                FinishTimeEvolutionView(
                    // `viewModel.race`, not the view's own stale `let race` —
                    // after a GPX import updates the view model (see
                    // `applyCourseUpdate`), re-entering this NavigationLink
                    // must see the persisted course, not the pre-import copy
                    // captured at this view's `init`.
                    race: viewModel.race,
                    estimate: estimate,
                    experience: viewModel.athleteExperience,
                    trainingPhilosophy: viewModel.athleteTrainingPhilosophy,
                    preferredRunsPerWeek: viewModel.athletePreferredRunsPerWeek,
                    raceRepository: raceRepository,
                    onCourseUpdated: { updatedRace in
                        Task { await viewModel.applyCourseUpdate(updatedRace) }
                    }
                )
            } label: {
                scenarioCardsBody(estimate, showsChartCue: true)
            }
            .buttonStyle(.plain)
        } else {
            scenarioCardsBody(estimate, showsChartCue: false)
        }
    }

    private func scenarioCardsBody(_ estimate: FinishEstimate, showsChartCue: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Predicted Finish Time")
                    .font(.headline)

                HStack(spacing: Theme.Spacing.sm) {
                    scenarioCard(
                        title: String(localized: "fe.scn.optimistic", defaultValue: "Optimistic"),
                        time: estimate.optimisticTime,
                        color: Theme.Colors.success
                    )
                    scenarioCard(
                        title: String(localized: "fe.scn.expected", defaultValue: "Expected"),
                        time: estimate.expectedTime,
                        color: Theme.Colors.primary
                    )
                    scenarioCard(
                        title: String(localized: "fe.scn.conservative", defaultValue: "Conservative"),
                        time: estimate.conservativeTime,
                        color: Theme.Colors.warning
                    )
                }

                if !showsChartCue {
                    Text("Race is too close to the start of your plan to project an evolution curve.")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
            .padding(.bottom, Theme.Spacing.sm)

            if showsChartCue {
                EvolutionCTAFooter()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumChartCardStyle(tint: Theme.Colors.primary)
    }

    func scenarioCard(title: String, time: TimeInterval, color: Color) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(FinishEstimate.formatDuration(time, raceDistanceKm: viewModel.race.distanceKm))
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(AccessibilityFormatters.duration(time))")
    }

    // MARK: - Confidence + Data Source
    // Previously two separate cards (a data-source explainer + a
    // confidence bar) that said much of the same thing in different
    // words — both boiling down to "here's why this range is what it is,
    // and here's a number for how much to trust it." Fused into one
    // card, same size as either original, keeping the confidence % bar
    // (the one piece of information that's genuinely its own signal) and
    // the source-specific explainer (the more actionable of the two
    // texts — it tells the athlete what to actually DO to tighten the
    // range, not just restates the percentage in words).

    func confidenceSection(_ estimate: FinishEstimate, source: FinishPredictionSource?) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                if let source {
                    Image(systemName: dataSourceIcon(source))
                        .foregroundStyle(dataSourceColor(source))
                        .font(.subheadline)
                        .accessibilityHidden(true)
                    Text(source.shortLabel)
                        .font(.subheadline.bold())
                        .foregroundStyle(dataSourceColor(source))
                } else {
                    Text("Confidence")
                        .font(.headline)
                }
                Spacer()
                Text(String(format: "%.0f%%", estimate.confidencePercent))
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            ProgressView(value: estimate.confidencePercent, total: 100)
                .tint(confidenceColor(estimate.confidencePercent))

            Text(source?.explainer ?? confidenceLabel(estimate.confidencePercent))
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .futuristicGlassStyle(phaseTint: source.map(dataSourceColor) ?? confidenceColor(estimate.confidencePercent))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(source?.shortLabel ?? "Confidence"). \(source?.explainer ?? confidenceLabel(estimate.confidencePercent)) \(Int(estimate.confidencePercent)) percent."
        )
    }

    func confidenceColor(_ percent: Double) -> Color {
        if percent >= 70 { return Theme.Colors.success }
        if percent >= 50 { return Theme.Colors.warning }
        return Theme.Colors.danger
    }

    func confidenceLabel(_ percent: Double) -> String {
        if percent >= 70 {
            return String(localized: "fe.confidence.strong", defaultValue: "Strong prediction, good training data available")
        }
        if percent >= 50 {
            return String(localized: "fe.confidence.moderate", defaultValue: "Moderate prediction, more training data would improve accuracy")
        }
        return String(localized: "fe.confidence.low", defaultValue: "Low confidence, keep training to improve prediction accuracy")
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
                Text(String(
                    format: String(localized: "fe.calibration.avgAccuracy", defaultValue: "Avg. accuracy: %.0f%%"),
                    accuracy
                ))
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
            return String(localized: "fe.calibration.adjustedDown", defaultValue: "Model adjusted down, you're faster than predicted")
        }
        return String(localized: "fe.calibration.adjustedUp", defaultValue: "Model adjusted up, you're slower than predicted")
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
