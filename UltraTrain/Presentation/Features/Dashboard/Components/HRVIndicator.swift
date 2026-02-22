import SwiftUI

struct HRVIndicator: View {
    let currentHRV: Double
    let trend: HRVAnalyzer.TrendDirection
    let sevenDayAverage: Double

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("HRV")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                HStack(spacing: 4) {
                    Text("\(Int(currentHRV))")
                        .font(.subheadline.bold().monospacedDigit())
                    Text("ms")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    Image(systemName: trendIcon)
                        .font(.caption2)
                        .foregroundStyle(trendColor)
                        .accessibilityHidden(true)
                }
            }
            Divider().frame(height: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text("7d Avg")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text("\(Int(sevenDayAverage)) ms")
                    .font(.caption.monospacedDigit())
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Heart rate variability: \(Int(currentHRV)) milliseconds, \(trendAccessibilityLabel). 7-day average: \(Int(sevenDayAverage)) milliseconds")
    }

    private var trendAccessibilityLabel: String {
        switch trend {
        case .improving: "improving"
        case .stable: "stable"
        case .declining: "declining"
        }
    }

    private var trendIcon: String {
        switch trend {
        case .improving: "arrow.up.right"
        case .stable: "arrow.right"
        case .declining: "arrow.down.right"
        }
    }

    private var trendColor: Color {
        switch trend {
        case .improving: Theme.Colors.success
        case .stable: Theme.Colors.secondaryLabel
        case .declining: Theme.Colors.danger
        }
    }
}
