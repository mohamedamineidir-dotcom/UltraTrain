import SwiftUI

struct InjuryRiskAlertBanner: View {
    let alerts: [InjuryRiskAlert]

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(sortedAlerts) { alert in
                alertCard(alert)
            }
        }
    }

    private var sortedAlerts: [InjuryRiskAlert] {
        alerts.sorted { $0.severity == .critical && $1.severity != .critical }
    }

    private func alertCard(_ alert: InjuryRiskAlert) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: alertIcon(alert.severity))
                    .foregroundStyle(alertColor(alert.severity))
                    .accessibilityHidden(true)
                Text(alert.message)
                    .font(.subheadline)
                    .lineLimit(2)
            }

            Text(alert.recommendation)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(alertColor(alert.severity).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(alertColor(alert.severity).opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(alert.severity == .critical ? "Critical" : "Warning") alert: \(alert.message). \(alert.recommendation)")
    }

    private func alertIcon(_ severity: AlertSeverity) -> String {
        switch severity {
        case .critical: "exclamationmark.triangle.fill"
        case .warning: "exclamationmark.circle.fill"
        }
    }

    private func alertColor(_ severity: AlertSeverity) -> Color {
        switch severity {
        case .critical: Theme.Colors.danger
        case .warning: Theme.Colors.warning
        }
    }
}
