import SwiftUI

struct DashboardZoneDistributionCard: View {
    let distribution: [HeartRateZoneDistribution]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Weekly HR Zones")
                .font(.headline)

            if hasData {
                stackedBar
                legend
            } else {
                Text("No heart rate data this week")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chartSummary)
    }

    // MARK: - Stacked Bar

    private var stackedBar: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(distribution) { zone in
                    if zone.percentage > 0 {
                        Rectangle()
                            .fill(zoneColor(zone.zone))
                            .frame(width: geo.size.width * zone.percentage / 100)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .frame(height: 24)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(distribution) { zone in
                if zone.percentage > 0 {
                    HStack(spacing: 2) {
                        Circle()
                            .fill(zoneColor(zone.zone))
                            .frame(width: 8, height: 8)
                        Text("Z\(zone.zone) \(Int(zone.percentage))%")
                            .font(.caption2.monospacedDigit())
                    }
                }
            }
        }
        .foregroundStyle(Theme.Colors.secondaryLabel)
    }

    // MARK: - Helpers

    private var hasData: Bool {
        distribution.contains { $0.durationSeconds > 0 }
    }

    private var chartSummary: String {
        guard hasData else { return "Weekly heart rate zones, no data" }
        let dominant = distribution.max(by: { $0.percentage < $1.percentage })
        let desc = dominant.map { "Most time in \($0.zoneName) at \(Int($0.percentage))%." } ?? ""
        return "Weekly heart rate zones. \(desc)"
    }

    private func zoneColor(_ zone: Int) -> Color {
        switch zone {
        case 1: return Theme.Colors.zone1
        case 2: return Theme.Colors.zone2
        case 3: return Theme.Colors.zone3
        case 4: return Theme.Colors.zone4
        case 5: return Theme.Colors.zone5
        default: return Theme.Colors.zone1
        }
    }
}
