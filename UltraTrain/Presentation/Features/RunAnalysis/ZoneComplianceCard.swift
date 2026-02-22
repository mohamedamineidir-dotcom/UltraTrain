import SwiftUI

struct ZoneComplianceCard: View {
    let compliance: ZoneComplianceCalculator.ZoneCompliance

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Zone Compliance")
                    .font(.headline)
                Spacer()
                ratingBadge
            }

            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.md) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Target: Zone \(compliance.targetZone)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    Text(formatTime(compliance.timeInTargetZone) + " / " + formatTime(compliance.totalTimeWithHR))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }

                Spacer()

                Text(String(format: "%.0f%%", compliance.compliancePercent))
                    .font(.title.bold().monospaced())
                    .foregroundStyle(ratingColor)
            }

            distributionBars
        }
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Rating Badge

    private var ratingBadge: some View {
        Text(compliance.rating.rawValue.capitalized)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(ratingColor)
            .clipShape(Capsule())
    }

    // MARK: - Distribution Bars

    private var distributionBars: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ForEach(1...5, id: \.self) { zone in
                let pct = compliance.zoneDistribution[zone, default: 0]
                HStack(spacing: Theme.Spacing.sm) {
                    Text("Z\(zone)")
                        .font(.caption2.bold().monospacedDigit())
                        .frame(width: 22, alignment: .leading)
                        .foregroundStyle(Theme.Colors.secondaryLabel)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 12)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(zoneColor(zone))
                                .frame(width: max(0, geometry.size.width * pct / 100), height: 12)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(zoneColor(zone), lineWidth: compliance.targetZone == zone ? 2 : 0)
                                .frame(height: 12)
                        )
                    }
                    .frame(height: 12)

                    Text(String(format: "%.0f%%", pct))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .frame(width: 32, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Helpers

    private var ratingColor: Color {
        switch compliance.rating {
        case .excellent: .green
        case .good: .blue
        case .fair: .orange
        case .poor: .red
        }
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

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private var accessibilitySummary: String {
        "Zone compliance: \(String(format: "%.0f%%", compliance.compliancePercent)), rated \(compliance.rating.rawValue). Target zone \(compliance.targetZone). Time in target: \(formatTime(compliance.timeInTargetZone)) of \(formatTime(compliance.totalTimeWithHR))."
    }
}
