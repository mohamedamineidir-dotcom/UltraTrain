import SwiftUI

struct OptimalSessionCard: View {
    let session: OptimalSession

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            headerRow
            detailRow
            reasoningText
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .foregroundStyle(Theme.Colors.primary)
                .accessibilityHidden(true)
            Text("AI Suggested Session")
                .font(.subheadline.bold())
            Spacer()
            Text("\(session.confidencePercent)%")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    private var detailRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName(for: session.recommendedType))
                    .font(.headline)
                Text(session.intensity.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(intensityColor)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f km", session.distanceKm))
                    .font(.subheadline.bold())
                if session.elevationGainM > 0 {
                    Text("\(Int(session.elevationGainM)) m D+")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
        }
    }

    private var reasoningText: some View {
        Text(session.reasoning)
            .font(.caption)
            .foregroundStyle(Theme.Colors.secondaryLabel)
            .lineLimit(3)
    }

    // MARK: - Helpers

    private func displayName(for type: SessionType) -> String {
        switch type {
        case .longRun: return "Long Run"
        case .tempo: return "Tempo"
        case .intervals: return "Intervals"
        case .verticalGain: return "Vertical Gain"
        case .backToBack: return "Back-to-Back"
        case .recovery: return "Recovery"
        case .crossTraining: return "Cross Training"
        case .rest: return "Rest"
        }
    }

    private var intensityColor: Color {
        switch session.intensity {
        case .easy: return Theme.Colors.success
        case .moderate: return Theme.Colors.warning
        case .hard: return Theme.Colors.danger.opacity(0.8)
        case .maxEffort: return Theme.Colors.danger
        }
    }
}
