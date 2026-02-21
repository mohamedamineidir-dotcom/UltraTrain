import SwiftUI

struct FatigueAlertCard: View {
    let patterns: [FatiguePattern]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            headerRow
            ForEach(patterns) { pattern in
                patternRow(pattern)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.warning.opacity(0.08))
        )
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.Colors.warning)
                .accessibilityHidden(true)
            Text("Fatigue Alerts")
                .font(.subheadline.bold())
            Spacer()
        }
    }

    private func patternRow(_ pattern: FatiguePattern) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: pattern.icon)
                .font(.caption)
                .foregroundStyle(colorForSeverity(pattern.severity))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(titleForType(pattern.type))
                    .font(.caption.bold())
                Text(pattern.recommendation)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
        }
    }

    // MARK: - Helpers

    private func colorForSeverity(_ severity: FatigueSeverity) -> Color {
        switch severity {
        case .mild: return .yellow
        case .moderate: return .orange
        case .significant: return .red
        }
    }

    private func titleForType(_ type: FatiguePatternType) -> String {
        switch type {
        case .paceDecline: return "Pace Decline"
        case .heartRateDrift: return "Heart Rate Drift"
        case .sleepQualityDecline: return "Sleep Quality Drop"
        case .rpeTrend: return "Rising Effort"
        case .compoundFatigue: return "Compound Fatigue"
        }
    }
}
