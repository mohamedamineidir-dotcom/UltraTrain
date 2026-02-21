import SwiftUI

struct LiveHRZoneIndicator: View {
    let state: LiveHRZoneTracker.LiveZoneState
    let heartRate: Int?

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            zoneBadge

            heartRateDisplay

            Spacer()

            timeInZone

            targetIndicator
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Zone Badge

    private var zoneBadge: some View {
        VStack(spacing: 2) {
            Text("Z\(state.currentZone)")
                .font(.headline.bold())
            Text(state.currentZoneName)
                .font(.caption2)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(zoneColor(state.currentZone))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
    }

    // MARK: - Heart Rate

    private var heartRateDisplay: some View {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text(heartRate.map { "\($0)" } ?? "--")
                .font(.title.bold().monospacedDigit())
            Text("bpm")
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Time in Zone

    private var timeInZone: some View {
        VStack(spacing: 2) {
            Text(formatTime(state.timeInCurrentZone))
                .font(.subheadline.bold().monospacedDigit())
            Text("in zone")
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Target Indicator

    @ViewBuilder
    private var targetIndicator: some View {
        if let target = state.targetZone {
            Image(systemName: targetIconName(currentZone: state.currentZone, targetZone: target))
                .font(.title3.bold())
                .foregroundStyle(state.isInTargetZone ? .green : .orange)
        }
    }

    // MARK: - Helpers

    private func targetIconName(currentZone: Int, targetZone: Int) -> String {
        if currentZone == targetZone {
            return "checkmark.circle.fill"
        } else if currentZone > targetZone {
            return "arrow.down.circle.fill"
        } else {
            return "arrow.up.circle.fill"
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func zoneColor(_ zone: Int) -> Color {
        switch zone {
        case 1: .blue
        case 2: .green
        case 3: .yellow
        case 4: .orange
        case 5: .red
        default: .gray
        }
    }

    private var accessibilitySummary: String {
        let hr = heartRate.map { "\($0) beats per minute" } ?? "no reading"
        let target = state.targetZone.map { state.isInTargetZone ? "On target zone \($0)" : "Target zone \($0)" } ?? ""
        return "Zone \(state.currentZone) \(state.currentZoneName), \(hr), \(formatTime(state.timeInCurrentZone)) in zone. \(target)"
    }
}
