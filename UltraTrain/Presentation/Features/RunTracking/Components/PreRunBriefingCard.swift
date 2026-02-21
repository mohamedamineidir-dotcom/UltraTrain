import SwiftUI

struct PreRunBriefingCard: View {
    let briefing: PreRunBriefing

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            headerRow

            if let readiness = briefing.readinessStatus {
                readinessRow(readiness)
            }

            if let adjustment = briefing.adaptiveAdjustment {
                adjustmentRow(adjustment)
            }

            if !briefing.fatigueAlerts.isEmpty {
                fatigueAlertsSection
            }

            focusPointRow

            if let pacing = briefing.pacingRecommendation {
                infoRow(icon: "speedometer", text: pacing)
            }

            if let nutrition = briefing.nutritionReminder {
                infoRow(icon: "fork.knife", text: nutrition)
            }

            if let summary = briefing.recentPerformanceSummary {
                infoRow(icon: "chart.bar.fill", text: summary)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .font(.title3)
                .foregroundStyle(Theme.Colors.primary)
                .accessibilityHidden(true)
            Text("Pre-Run Briefing")
                .font(.headline)
            Spacer()
        }
    }

    private func readinessRow(_ status: RecoveryStatus) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(colorForStatus(status))
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)
            Text("Readiness: \(status.rawValue.capitalized)")
                .font(.subheadline.bold())
            if let score = briefing.readinessScore {
                Text("(\(score)/100)")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
        }
    }

    private func adjustmentRow(
        _ adjustment: AdaptiveSessionAdjustment
    ) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(
                systemName: adjustment.isDowngrade
                    ? "arrow.down.circle.fill"
                    : "arrow.up.circle.fill"
            )
            .foregroundStyle(
                adjustment.isDowngrade
                    ? Theme.Colors.warning
                    : Theme.Colors.success
            )
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(
                    adjustment.isDowngrade
                        ? "Session Adjusted Down"
                        : "Session Upgraded"
                )
                .font(.subheadline.bold())
                Text(adjustment.reasonText)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
        }
    }

    private var fatigueAlertsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ForEach(briefing.fatigueAlerts) { alert in
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: alert.icon)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.warning)
                        .accessibilityHidden(true)
                    Text(alert.recommendation)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
        }
    }

    private var focusPointRow: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "target")
                .foregroundStyle(Theme.Colors.primary)
                .accessibilityHidden(true)
            Text(briefing.focusPoint)
                .font(.subheadline)
            Spacer()
        }
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityHidden(true)
            Text(text)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Spacer()
        }
    }

    private func colorForStatus(_ status: RecoveryStatus) -> Color {
        switch status {
        case .excellent: return Theme.Colors.success
        case .good: return Theme.Colors.success.opacity(0.7)
        case .moderate: return Theme.Colors.warning
        case .poor: return Theme.Colors.danger.opacity(0.7)
        case .critical: return Theme.Colors.danger
        }
    }
}
