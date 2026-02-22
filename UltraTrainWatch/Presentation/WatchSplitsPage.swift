import SwiftUI

struct WatchSplitsPage: View {
    let splits: [WatchSplit]

    var body: some View {
        ScrollView {
            if splits.isEmpty {
                emptyState
            } else {
                splitsList
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "flag.slash")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("No splits yet")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }

    // MARK: - Splits List

    private var splitsList: some View {
        VStack(spacing: 4) {
            ForEach(splits, id: \.id) { split in
                splitRow(split)
            }
        }
        .padding(.horizontal, 4)
    }

    private func splitRow(_ split: WatchSplit) -> some View {
        HStack {
            Text("KM \(split.kilometerNumber)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)

            Text(WatchRunCalculator.formatPace(split.duration))
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(paceColor(for: split))

            Spacer()

            if let hr = split.averageHeartRate {
                Image(systemName: "heart.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.red)
                Text("\(hr)")
                    .font(.caption2.monospacedDigit())
            }

            elevationLabel(split.elevationChangeM)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(isHighlighted(split) ? highlightColor(split).opacity(0.15) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Helpers

    private func elevationLabel(_ changeM: Double) -> some View {
        Group {
            if changeM >= 1 {
                Text("+\(Int(changeM))m")
                    .font(.system(size: 9).monospacedDigit())
                    .foregroundStyle(.green)
            } else if changeM <= -1 {
                Text("\(Int(changeM))m")
                    .font(.system(size: 9).monospacedDigit())
                    .foregroundStyle(.orange)
            } else {
                Text("0m")
                    .font(.system(size: 9).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var fastestPace: TimeInterval? {
        splits.min(by: { $0.duration < $1.duration })?.duration
    }

    private var slowestPace: TimeInterval? {
        splits.min(by: { $0.duration > $1.duration })?.duration
    }

    private func isHighlighted(_ split: WatchSplit) -> Bool {
        guard splits.count >= 2 else { return false }
        return split.duration == fastestPace || split.duration == slowestPace
    }

    private func highlightColor(_ split: WatchSplit) -> Color {
        if split.duration == fastestPace { return .green }
        if split.duration == slowestPace { return .red }
        return .clear
    }

    private func paceColor(for split: WatchSplit) -> Color {
        guard splits.count >= 2 else { return .white }
        if split.duration == fastestPace { return .green }
        if split.duration == slowestPace { return .red }
        return .white
    }
}
