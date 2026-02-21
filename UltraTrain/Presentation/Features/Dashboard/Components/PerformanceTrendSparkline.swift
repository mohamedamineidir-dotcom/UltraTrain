import SwiftUI

struct PerformanceTrendSparkline: View {
    let trend: PerformanceTrend

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            headerRow
            summaryText
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack {
            Image(systemName: trend.icon)
                .foregroundStyle(colorForDirection(trend.trendDirection))
                .accessibilityHidden(true)
            Text(trend.displayName)
                .font(.caption.bold())
            Spacer()
            HStack(spacing: 2) {
                Image(systemName: trend.trendArrow)
                    .font(.caption2)
                    .accessibilityHidden(true)
                Text(String(format: "%.1f%%", abs(trend.changePercent)))
                    .font(.caption2)
            }
            .foregroundStyle(colorForDirection(trend.trendDirection))
        }
    }

    private var summaryText: some View {
        Text(trend.summary)
            .font(.caption2)
            .foregroundStyle(Theme.Colors.secondaryLabel)
            .lineLimit(2)
    }

    // MARK: - Helpers

    private func colorForDirection(_ direction: PerformanceTrendDirection) -> Color {
        switch direction {
        case .improving: return Theme.Colors.success
        case .stable: return Theme.Colors.secondaryLabel
        case .declining: return Theme.Colors.danger
        }
    }
}
