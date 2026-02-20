import SwiftUI

struct CheckpointSplitsCard: View {
    @Environment(\.unitPreference) private var units
    let race: Race
    let estimate: FinishEstimate

    @State private var showSegmentTime = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            headerRow
            columnHeaders
            ForEach(Array(estimate.checkpointSplits.enumerated()), id: \.element.id) { index, split in
                splitRow(split, index: index)
                if split.id != estimate.checkpointSplits.last?.id {
                    Divider()
                }
            }
            Divider()
            finishRow
        }
        .cardStyle()
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("Checkpoint Splits")
                .font(.headline)
            Spacer()
            Picker("Time Mode", selection: $showSegmentTime) {
                Text("Cumulative").tag(false)
                Text("Segment").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
        }
    }

    // MARK: - Column Headers

    private var columnHeaders: some View {
        HStack(spacing: 0) {
            Text("Checkpoint")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Dist")
                .frame(width: 42, alignment: .trailing)
            Text("D+")
                .frame(width: 42, alignment: .trailing)
            Text("Best")
                .frame(width: 52, alignment: .trailing)
            Text("Expected")
                .frame(width: 62, alignment: .trailing)
            Text("Worst")
                .frame(width: 52, alignment: .trailing)
        }
        .font(.caption2.bold())
        .foregroundStyle(Theme.Colors.secondaryLabel)
    }

    // MARK: - Split Row

    private func splitRow(_ split: CheckpointSplit, index: Int) -> some View {
        let previousSplit: CheckpointSplit? = index > 0 ? estimate.checkpointSplits[index - 1] : nil
        let optimistic = showSegmentTime
            ? split.optimisticTime - (previousSplit?.optimisticTime ?? 0)
            : split.optimisticTime
        let expected = showSegmentTime
            ? split.expectedTime - (previousSplit?.expectedTime ?? 0)
            : split.expectedTime
        let conservative = showSegmentTime
            ? split.conservativeTime - (previousSplit?.conservativeTime ?? 0)
            : split.conservativeTime

        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 0) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(split.checkpointName)
                        .lineLimit(1)
                    if split.hasAidStation {
                        Image(systemName: "cross.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(Theme.Colors.success)
                            .accessibilityLabel("Aid station")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(formatDist(split.segmentDistanceKm))
                    .frame(width: 42, alignment: .trailing)
                Text(formatElev(split.segmentElevationGainM))
                    .frame(width: 42, alignment: .trailing)
                Text(FinishEstimate.formatDuration(optimistic))
                    .frame(width: 52, alignment: .trailing)
                Text(FinishEstimate.formatDuration(expected))
                    .frame(width: 62, alignment: .trailing)
                    .fontWeight(.medium)
                Text(FinishEstimate.formatDuration(conservative))
                    .frame(width: 52, alignment: .trailing)
            }
            .font(.caption.monospacedDigit())

            if !showSegmentTime, race.date > .distantPast {
                let arrival = race.date.addingTimeInterval(expected)
                Text(arrival.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
    }

    // MARK: - Finish Row

    private var finishRow: some View {
        HStack(spacing: 0) {
            Text("FINISH")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(formatDist(race.distanceKm))
                .frame(width: 42, alignment: .trailing)
            Text(formatElev(race.elevationGainM))
                .frame(width: 42, alignment: .trailing)
            Text(FinishEstimate.formatDuration(estimate.optimisticTime))
                .frame(width: 52, alignment: .trailing)
            Text(FinishEstimate.formatDuration(estimate.expectedTime))
                .frame(width: 62, alignment: .trailing)
                .fontWeight(.bold)
            Text(FinishEstimate.formatDuration(estimate.conservativeTime))
                .frame(width: 52, alignment: .trailing)
        }
        .font(.caption.monospacedDigit())
    }

    // MARK: - Formatting

    private func formatDist(_ km: Double) -> String {
        let value = UnitFormatter.distanceValue(km, unit: units)
        return String(format: "%.1f", value)
    }

    private func formatElev(_ meters: Double) -> String {
        let value = UnitFormatter.elevationValue(meters, unit: units)
        return String(format: "%.0f", value)
    }
}
