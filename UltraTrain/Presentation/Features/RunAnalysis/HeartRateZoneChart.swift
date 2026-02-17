import SwiftUI
import Charts

struct HeartRateZoneChart: View {
    let distribution: [HeartRateZoneDistribution]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Heart Rate Zones")
                .font(.headline)

            Chart(distribution) { zone in
                BarMark(
                    x: .value("Percentage", zone.percentage),
                    y: .value("Zone", zone.zoneName)
                )
                .foregroundStyle(zoneColor(zone.zone))
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    if zone.percentage > 0 {
                        Text(String(format: "%.0f%%", zone.percentage))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let pct = value.as(Double.self) {
                            Text(String(format: "%.0f%%", pct))
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chartSummary)
    }

    private var chartSummary: String {
        guard !distribution.isEmpty else { return "Heart rate zones chart, no data" }
        let dominant = distribution.max(by: { $0.percentage < $1.percentage })
        let desc = dominant.map { "Most time in \($0.zoneName) at \(Int($0.percentage))%." } ?? ""
        return "Heart rate zones chart. \(distribution.count) zones. \(desc)"
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
