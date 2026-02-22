import SwiftUI

struct PersonalRecordsWallView: View {
    @Environment(\.unitPreference) private var units
    let records: [PersonalRecord]

    private var overallRecords: [PersonalRecord] {
        let overallTypes: Set<PersonalRecordType> = [
            .longestDistance, .mostElevation, .fastestPace, .longestDuration
        ]
        return records.filter { overallTypes.contains($0.type) }
    }

    private var distanceRecords: [PersonalRecord] {
        let distanceTypes: Set<PersonalRecordType> = [
            .fastest5K, .fastest10K, .fastestHalf, .fastestMarathon, .fastest50K, .fastest100K
        ]
        return records.filter { distanceTypes.contains($0.type) }
    }

    var body: some View {
        List {
            if !overallRecords.isEmpty {
                Section("Overall Records") {
                    ForEach(overallRecords) { record in
                        recordRow(record)
                    }
                }
            }

            if !distanceRecords.isEmpty {
                Section("Distance Records") {
                    ForEach(distanceRecords) { record in
                        recordRow(record)
                    }
                }
            }

            if records.isEmpty {
                ContentUnavailableView(
                    "No Records Yet",
                    systemImage: "trophy",
                    description: Text("Complete some runs to start setting personal records.")
                )
            }
        }
        .navigationTitle("Personal Records")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Record Row

    private func recordRow(_ record: PersonalRecord) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: iconName(for: record.type))
                .font(.title2)
                .foregroundStyle(iconColor(for: record.type))
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(label(for: record.type))
                    .font(.subheadline.bold())

                Text(record.date.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            Text(formattedValue(for: record))
                .font(.title3.bold().monospacedDigit())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label(for: record.type)): \(formattedValue(for: record)), set on \(record.date.formatted(.dateTime.month(.abbreviated).day().year()))")
    }

    // MARK: - Helpers

    private func iconName(for type: PersonalRecordType) -> String {
        switch type {
        case .longestDistance: "arrow.left.and.right"
        case .mostElevation: "mountain.2.fill"
        case .fastestPace: "bolt.fill"
        case .longestDuration: "timer"
        case .fastest5K, .fastest10K, .fastestHalf, .fastestMarathon, .fastest50K, .fastest100K: "trophy.fill"
        }
    }

    private func iconColor(for type: PersonalRecordType) -> Color {
        switch type {
        case .longestDistance: Theme.Colors.primary
        case .mostElevation: Theme.Colors.success
        case .fastestPace: Theme.Colors.warning
        case .longestDuration: Theme.Colors.zone2
        case .fastest5K, .fastest10K, .fastestHalf, .fastestMarathon, .fastest50K, .fastest100K: Theme.Colors.primary
        }
    }

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
