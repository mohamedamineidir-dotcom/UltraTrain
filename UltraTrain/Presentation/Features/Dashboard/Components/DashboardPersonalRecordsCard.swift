import SwiftUI

struct DashboardPersonalRecordsCard: View {
    @Environment(\.unitPreference) private var units
    let records: [PersonalRecord]

    private var latestRecord: PersonalRecord? {
        records.max(by: { $0.date < $1.date })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Theme.Colors.warning)
                Text("Personal Records")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            if let latest = latestRecord {
                HStack(spacing: Theme.Spacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label(for: latest.type))
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                        Text(formattedValue(for: latest))
                            .font(.title3.bold().monospacedDigit())
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(records.count) records")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                        Text(latest.date.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Helpers

    private func label(for type: PersonalRecordType) -> String {
        switch type {
        case .longestDistance: "Longest Run"
        case .mostElevation: "Most Elevation"
        case .fastestPace: "Fastest Pace"
        case .longestDuration: "Longest Duration"
        case .fastest5K: "Fastest 5K"
        case .fastest10K: "Fastest 10K"
        case .fastestHalf: "Fastest Half"
        case .fastestMarathon: "Fastest Marathon"
        case .fastest50K: "Fastest 50K"
        case .fastest100K: "Fastest 100K"
        }
    }

    private func formattedValue(for record: PersonalRecord) -> String {
        switch record.type {
        case .longestDistance:
            return UnitFormatter.formatDistance(record.value, unit: units)
        case .mostElevation:
            return UnitFormatter.formatElevation(record.value, unit: units)
        case .fastestPace:
            return RunStatisticsCalculator.formatPace(record.value, unit: units) + " " + UnitFormatter.paceLabel(units)
        case .longestDuration, .fastest5K, .fastest10K, .fastestHalf, .fastestMarathon, .fastest50K, .fastest100K:
            let hours = Int(record.value) / 3600
            let minutes = (Int(record.value) % 3600) / 60
            if hours > 0 {
                return String(format: "%dh %02dm", hours, minutes)
            } else {
                return String(format: "%dm", minutes)
            }
        }
    }
}
