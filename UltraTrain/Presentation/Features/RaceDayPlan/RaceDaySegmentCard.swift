import SwiftUI

struct RaceDaySegmentCard: View {
    @Environment(\.unitPreference) private var units
    let segment: RaceDaySegment

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            headerRow
            statsRow
            if segment.targetPaceSecondsPerKm > 0 {
                Divider()
                pacingSection
            }
            if segment.hasAidStation && segment.aidStationDwellTime > 0 {
                dwellTimeRow
            }
            if !segment.nutritionEntries.isEmpty {
                Divider()
                nutritionSection
            }
            Divider()
            cumulativeFooter
        }
        .cardStyle()
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            HStack(spacing: Theme.Spacing.xs) {
                Text(segment.checkpointName)
                    .font(.subheadline.bold())
                if segment.hasAidStation {
                    Image(systemName: "cross.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.Colors.success)
                        .accessibilityLabel("Aid station")
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(FinishEstimate.formatDuration(segment.expectedCumulativeTime))
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(Theme.Colors.primary)
                Text(segment.expectedArrivalTime.formatted(.dateTime.hour().minute()))
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            Label(
                UnitFormatter.formatDistance(segment.segmentDistanceKm, unit: units),
                systemImage: "point.topleft.down.to.point.bottomright.curvepath"
            )
            Label(
                "\(UnitFormatter.formatElevation(segment.segmentElevationGainM, unit: units)) D+",
                systemImage: "mountain.2"
            )
            if segment.segmentElevationLossM > 0 {
                Label(
                    "\(UnitFormatter.formatElevation(segment.segmentElevationLossM, unit: units)) D-",
                    systemImage: "arrow.down.right"
                )
            }
            Label(
                FinishEstimate.formatDuration(segment.expectedSegmentDuration),
                systemImage: "clock"
            )
        }
        .font(.caption)
        .foregroundStyle(Theme.Colors.secondaryLabel)
    }

    // MARK: - Pacing

    private var pacingSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Target Pace")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text(UnitFormatter.formatPace(segment.targetPaceSecondsPerKm, unit: units))
                    .font(.subheadline.bold().monospacedDigit())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Range")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text("\(UnitFormatter.formatPace(segment.aggressivePaceSecondsPerKm, unit: units)) – \(UnitFormatter.formatPace(segment.conservativePaceSecondsPerKm, unit: units))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()
            PacingZoneIndicator(zone: segment.pacingZone)

            if let hrRange = segment.targetHeartRateRange {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Target HR")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    Text("\(hrRange.lowerBound)-\(hrRange.upperBound) bpm")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(Theme.Colors.danger)
                }
            }
        }
    }

    private var dwellTimeRow: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "pause.circle.fill")
                .foregroundStyle(Theme.Colors.primary)
                .font(.caption)
            Text("Aid station stop: \(Int(segment.aidStationDwellTime / 60)) min")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Nutrition

    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Nutrition")
                .font(.caption.bold())
                .foregroundStyle(Theme.Colors.secondaryLabel)

            ForEach(segment.nutritionEntries) { entry in
                NutritionEntryRow(entry: entry)
            }
        }
    }

    // MARK: - Cumulative Footer

    private var cumulativeFooter: some View {
        HStack(spacing: Theme.Spacing.md) {
            Label("\(segment.cumulativeCalories) kcal", systemImage: "flame.fill")
                .foregroundStyle(.orange)
            Label("\(segment.cumulativeHydrationMl) ml", systemImage: "drop.fill")
                .foregroundStyle(.blue)
            Label("\(segment.cumulativeSodiumMg) mg Na+", systemImage: "pill.fill")
                .foregroundStyle(.gray)
        }
        .font(.caption2)
    }
}
