import SwiftUI

struct HistoricalComparisonSection: View {
    let comparison: HistoricalComparison

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("vs Recent Runs")
                    .font(.headline)
                Spacer()
                paceTrendBadge
            }

            if !comparison.splitPRs.isEmpty {
                splitPRsRow
            }

            if !comparison.badges.isEmpty {
                badgesRow
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    // MARK: - Pace Trend

    private var paceTrendBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: trendIcon)
                .font(.caption)
            Text(trendText)
                .font(.caption.bold())
        }
        .foregroundStyle(trendColor)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            Capsule().fill(trendColor.opacity(0.15))
        )
    }

    private var trendIcon: String {
        switch comparison.paceTrend {
        case .improving: return "arrow.up.right"
        case .declining: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    private var trendText: String {
        switch comparison.paceTrend {
        case .improving: return "Faster"
        case .declining: return "Slower"
        case .stable: return "Stable"
        }
    }

    private var trendColor: Color {
        switch comparison.paceTrend {
        case .improving: return Theme.Colors.success
        case .declining: return Theme.Colors.danger
        case .stable: return Theme.Colors.secondaryLabel
        }
    }

    // MARK: - Split PRs

    private var splitPRsRow: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Split PRs")
                .font(.subheadline.bold())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(comparison.splitPRs) { pr in
                        VStack(spacing: 2) {
                            Image(systemName: "trophy.fill")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.warning)
                            Text("KM \(pr.kilometerNumber)")
                                .font(.caption2.bold())
                            Text(RunStatisticsCalculator.formatPace(pr.currentPace))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(Theme.Colors.success)
                        }
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .fill(Theme.Colors.warning.opacity(0.1))
                        )
                    }
                }
            }
        }
    }

    // MARK: - Badges

    private var badgesRow: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Achievements")
                .font(.subheadline.bold())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(comparison.badges) { badge in
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: badge.icon)
                                .font(.subheadline)
                                .foregroundStyle(Theme.Colors.primary)
                            VStack(alignment: .leading) {
                                Text(badge.title)
                                    .font(.caption.bold())
                                Text(badge.description)
                                    .font(.caption2)
                                    .foregroundStyle(Theme.Colors.secondaryLabel)
                                    .lineLimit(1)
                            }
                        }
                        .padding(Theme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .fill(Theme.Colors.primary.opacity(0.08))
                        )
                    }
                }
            }
        }
    }
}
