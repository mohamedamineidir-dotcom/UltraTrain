import SwiftUI

struct DashboardFinishEstimateCard: View {
    let estimate: FinishEstimate
    let race: Race
    /// Tap to recalculate the forecast from the latest completed training.
    var onRefresh: (() -> Void)? = nil
    /// When true (during the async recompute), the refresh icon spins.
    var isRefreshing: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Predicted finish")
                        .font(.headline)
                    Text(race.name)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                if let onRefresh {
                    Button {
                        onRefresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption.weight(.semibold))
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(
                                isRefreshing
                                    ? .linear(duration: 1).repeatForever(autoreverses: false)
                                    : .default,
                                value: isRefreshing
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isRefreshing)
                    .accessibilityLabel("Refresh forecast")
                    .accessibilityIdentifier("dashboard.forecastRefreshButton")
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
                    .accessibilityHidden(true)
            }

            HStack(spacing: 0) {
                scenarioColumn(
                    time: FinishEstimate.formatDuration(estimate.optimisticTime),
                    label: "Best",
                    color: Theme.Colors.success
                )

                Spacer()

                VStack(spacing: 4) {
                    Text(estimate.expectedTimeFormatted)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.Colors.primary)
                    Text("Expected")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }

                Spacer()

                scenarioColumn(
                    time: FinishEstimate.formatDuration(estimate.conservativeTime),
                    label: "Safe",
                    color: Theme.Colors.warning
                )
            }
            .padding(.vertical, Theme.Spacing.xs)

            // Confidence bar
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.Colors.secondaryLabel.opacity(0.1))
                        Capsule()
                            .fill(confidenceGradient)
                            .frame(width: geo.size.width * estimate.confidencePercent / 100)
                    }
                }
                .frame(height: 4)

                HStack {
                    Text("Confidence")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    Spacer()
                    Text("\(Int(estimate.confidencePercent))%")
                        .font(.caption2.bold().monospacedDigit())
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }

                Text(rangeHint)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
                    .padding(.top, 2)
            }
        }
        .appCardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var rangeHint: String {
        let best = FinishEstimate.formatDuration(estimate.optimisticTime)
        let safe = FinishEstimate.formatDuration(estimate.conservativeTime)
        return "Range \(best)–\(safe). Narrows as you complete sessions."
    }

    private var confidenceGradient: LinearGradient {
        LinearGradient(
            colors: [Theme.Colors.accentColor.opacity(0.6), Theme.Colors.accentColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var accessibilityDescription: String {
        let best = FinishEstimate.formatDuration(estimate.optimisticTime)
        let expected = estimate.expectedTimeFormatted
        let safe = FinishEstimate.formatDuration(estimate.conservativeTime)
        return "Race estimate for \(race.name). Best case \(best). Expected \(expected). Safe case \(safe). Confidence \(Int(estimate.confidencePercent)) percent."
    }

    private func scenarioColumn(time: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(time)
                .font(.system(.footnote, design: .rounded, weight: .semibold).monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }
}
