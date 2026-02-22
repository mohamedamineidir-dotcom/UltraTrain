import SwiftUI

struct WatchSplitBanner: View {
    let split: WatchSplit
    let previousPace: Double?

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flag.fill")
                .font(.caption2)
            Text("KM \(split.kilometerNumber)")
                .font(.caption2.bold())
            Text(WatchRunCalculator.formatPace(split.duration))
                .font(.caption.bold().monospacedDigit())
            comparisonArrow
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(paceColor.opacity(0.9))
        .clipShape(Capsule())
    }

    // MARK: - Private

    private var paceColor: Color {
        guard let previous = previousPace else { return .gray }
        if split.duration < previous {
            return .green
        } else if split.duration > previous {
            return .red
        }
        return .gray
    }

    @ViewBuilder
    private var comparisonArrow: some View {
        if let previous = previousPace {
            if split.duration < previous {
                Image(systemName: "arrow.down")
                    .font(.caption2.bold())
            } else if split.duration > previous {
                Image(systemName: "arrow.up")
                    .font(.caption2.bold())
            }
        }
    }
}
