import SwiftUI

struct PacingSummaryCard: View {
    @Environment(\.unitPreference) private var units
    let pacingResult: RacePacingCalculator.PacingResult
    let aidStationDwellSeconds: TimeInterval
    let onDwellTimeChanged: (TimeInterval) -> Void

    private var dwellMinutes: Int {
        Int(aidStationDwellSeconds / 60)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("Pacing Strategy", systemImage: "speedometer")
                .font(.headline)

            paceStats
            timeBreakdown

            if pacingResult.totalDwellTime > 0 {
                dwellTimeStepper
            }
        }
        .cardStyle()
    }

    // MARK: - Pace Stats

    private var paceStats: some View {
        HStack(spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Avg Target Pace")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text(UnitFormatter.formatPace(pacingResult.averageTargetPaceSecondsPerKm, unit: units))
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(Theme.Colors.primary)
            }

            Spacer()

            zoneBreakdown
        }
    }

    private var zoneBreakdown: some View {
        HStack(spacing: Theme.Spacing.xs) {
            let zones = pacingResult.segmentPacings.map(\.pacingZone)
            let easy = zones.filter { $0 == .easy }.count
            let moderate = zones.filter { $0 == .moderate }.count
            let hard = zones.filter { $0 == .hard }.count

            if easy > 0 { zoneBadge(count: easy, zone: .easy) }
            if moderate > 0 { zoneBadge(count: moderate, zone: .moderate) }
            if hard > 0 { zoneBadge(count: hard, zone: .hard) }
        }
    }

    private func zoneBadge(count: Int, zone: RacePacingCalculator.PacingZone) -> some View {
        Text("\(count) \(zone.label)")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(zone.color.opacity(0.12))
            .foregroundStyle(zone.color)
            .clipShape(Capsule())
    }

    // MARK: - Time Breakdown

    private var timeBreakdown: some View {
        HStack(spacing: Theme.Spacing.md) {
            timeColumn(
                label: "Moving Time",
                time: pacingResult.totalMovingTime
            )
            timeColumn(
                label: "Aid Stops",
                time: pacingResult.totalDwellTime
            )
            timeColumn(
                label: "Total Time",
                time: pacingResult.totalTimeWithDwell
            )
        }
    }

    private func timeColumn(label: String, time: TimeInterval) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(FinishEstimate.formatDuration(time))
                .font(.subheadline.bold().monospacedDigit())
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Dwell Time Stepper

    private var dwellTimeStepper: some View {
        HStack {
            Label("Aid Station Stop", systemImage: "pause.circle")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Spacer()
            Stepper(
                "\(dwellMinutes) min",
                value: Binding(
                    get: { dwellMinutes },
                    set: { onDwellTimeChanged(TimeInterval($0 * 60)) }
                ),
                in: 1...15
            )
            .font(.caption)
        }
    }
}
