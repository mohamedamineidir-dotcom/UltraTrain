import SwiftUI

struct CheckpointSplitsCard: View {
    @Environment(\.unitPreference) private var units
    let race: Race
    let estimate: FinishEstimate

    @State private var showSegmentTime = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            headerRow

            VStack(spacing: 0) {
                ForEach(Array(estimate.checkpointSplits.enumerated()), id: \.element.id) { index, split in
                    timelineRow(isLast: false) {
                        splitContent(split, index: index)
                    }
                }
                timelineRow(isLast: true) {
                    finishContent
                }
            }
        }
        .premiumChartCardStyle(tint: Theme.Colors.primary)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("Checkpoint Splits")
                .font(.headline)
            Spacer()
            Picker("Time Mode", selection: $showSegmentTime.animation(.easeInOut(duration: 0.15))) {
                Text("Cumulative").tag(false)
                Text("Segment").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
        }
    }

    // MARK: - Timeline Row
    // Each checkpoint is a node on a vertical timeline, connected by a
    // tinted line down to the next one — reads as a journey through the
    // race rather than another flat data table.

    private func timelineRow(isLast: Bool, @ViewBuilder content: () -> some View) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            VStack(spacing: 0) {
                nodeIcon(isLast: isLast)
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.primary.opacity(0.35), Theme.Colors.primary.opacity(0.08)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 26)

            content()
                .padding(.bottom, isLast ? 0 : Theme.Spacing.md)
        }
    }

    private func nodeIcon(isLast: Bool) -> some View {
        ZStack {
            Circle()
                .fill(
                    isLast
                        ? AnyShapeStyle(LinearGradient(colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                        : AnyShapeStyle(Theme.Colors.primary.opacity(0.18))
                )
                .frame(width: 26, height: 26)
            Image(systemName: isLast ? "flag.checkered" : "mappin")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(isLast ? .white : Theme.Colors.primary)
        }
    }

    // MARK: - Split Content

    /// Reserves the exact same vertical space regardless of time mode —
    /// the arrival clock time is always laid out, just invisible in
    /// Segment mode — so toggling never changes the card's height.
    private func splitContent(_ split: CheckpointSplit, index: Int) -> some View {
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

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: Theme.Spacing.xs) {
                Text(split.checkpointName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                if split.hasAidStation {
                    Image(systemName: "cross.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.danger)
                        .accessibilityLabel("Aid station")
                }
                Spacer(minLength: Theme.Spacing.sm)
                Text(
                    "\(formatDist(split.segmentDistanceKm)) \(UnitFormatter.distanceLabel(units))  ·  D+ \(formatElev(split.segmentElevationGainM)) \(UnitFormatter.elevationShortLabel(units))"
                )
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .lineLimit(1)
            }

            HStack(spacing: Theme.Spacing.md) {
                timeStat(color: Theme.Colors.success, label: "Best", value: FinishEstimate.formatDuration(optimistic, raceDistanceKm: race.distanceKm))
                timeStat(color: Theme.Colors.primary, label: "Expected", value: FinishEstimate.formatDuration(expected, raceDistanceKm: race.distanceKm), emphasized: true)
                timeStat(color: Theme.Colors.warning, label: "Worst", value: FinishEstimate.formatDuration(conservative, raceDistanceKm: race.distanceKm))
                Spacer(minLength: 0)
                arrivalTimeText(cumulativeExpected: split.expectedTime)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// Small colored time readout — reuses the app-wide optimistic
    /// (green) / expected (primary) / conservative (orange) convention.
    private func timeStat(color: Color, label: LocalizedStringKey, value: String, emphasized: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 3) {
                Circle().fill(color).frame(width: 5, height: 5)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Text(value)
                .font(.caption.monospacedDigit())
                .fontWeight(emphasized ? .bold : .semibold)
                .foregroundStyle(emphasized ? Theme.Colors.label : Theme.Colors.label.opacity(0.85))
        }
        .fixedSize()
    }

    /// Always occupies the same layout slot — populated with the
    /// wall-clock arrival estimate in Cumulative mode, invisible (but
    /// still reserving its space) in Segment mode, where an absolute
    /// arrival time wouldn't be meaningful anyway.
    @ViewBuilder
    private func arrivalTimeText(cumulativeExpected: TimeInterval) -> some View {
        if race.date > .distantPast {
            let arrival = race.date.addingTimeInterval(cumulativeExpected)
            HStack(spacing: 3) {
                Image(systemName: "clock")
                    .font(.system(size: 9))
                Text(arrival.formatted(.dateTime.hour().minute()))
                    .font(.caption2.monospacedDigit())
            }
            .foregroundStyle(Theme.Colors.secondaryLabel)
            .opacity(showSegmentTime ? 0 : 1)
            .accessibilityHidden(showSegmentTime)
        }
    }

    // MARK: - Finish Content

    private var finishContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: Theme.Spacing.xs) {
                Text("FINISH")
                    .font(.subheadline.bold())
                Spacer(minLength: Theme.Spacing.sm)
                Text(
                    "\(formatDist(race.distanceKm)) \(UnitFormatter.distanceLabel(units))  ·  D+ \(formatElev(race.elevationGainM)) \(UnitFormatter.elevationShortLabel(units))"
                )
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .lineLimit(1)
            }
            HStack(spacing: Theme.Spacing.md) {
                timeStat(color: Theme.Colors.success, label: "Best", value: FinishEstimate.formatDuration(estimate.optimisticTime, raceDistanceKm: race.distanceKm))
                timeStat(color: Theme.Colors.primary, label: "Expected", value: FinishEstimate.formatDuration(estimate.expectedTime, raceDistanceKm: race.distanceKm), emphasized: true)
                timeStat(color: Theme.Colors.warning, label: "Worst", value: FinishEstimate.formatDuration(estimate.conservativeTime, raceDistanceKm: race.distanceKm))
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(Theme.Colors.primary.opacity(0.10))
        )
        .accessibilityElement(children: .combine)
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
