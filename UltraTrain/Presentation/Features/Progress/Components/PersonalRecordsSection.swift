import SwiftUI

struct PersonalRecordsSection: View {
    let records: [PersonalRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Personal Records")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: Theme.Spacing.sm) {
                    ForEach(records) { record in
                        recordCard(record)
                    }
                }
            }
        }
    }

    // MARK: - Record Card

    private func recordCard(_ record: PersonalRecord) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Image(systemName: iconName(for: record.type))
                .font(.title3)
                .foregroundStyle(iconColor(for: record.type))

            Text(label(for: record.type))
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            Text(formattedValue(for: record))
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(Theme.Colors.label)

            Text(record.date.formatted(.dateTime.month(.abbreviated).day().year()))
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(width: 120, alignment: .leading)
        .padding(Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(Theme.Colors.secondaryBackground)
        }
    }

    // MARK: - Helpers

    private func iconName(for type: PersonalRecordType) -> String {
        switch type {
        case .longestDistance: "arrow.left.and.right"
        case .mostElevation: "mountain.2.fill"
        case .fastestPace: "bolt.fill"
        case .longestDuration: "timer"
        }
    }

    private func iconColor(for type: PersonalRecordType) -> Color {
        switch type {
        case .longestDistance: Theme.Colors.primary
        case .mostElevation: Theme.Colors.success
        case .fastestPace: Theme.Colors.warning
        case .longestDuration: Theme.Colors.zone2
        }
    }

    private func label(for type: PersonalRecordType) -> String {
        switch type {
        case .longestDistance: "Longest Run"
        case .mostElevation: "Most Elevation"
        case .fastestPace: "Fastest Pace"
        case .longestDuration: "Longest Duration"
        }
    }

    private func formattedValue(for record: PersonalRecord) -> String {
        switch record.type {
        case .longestDistance:
            return String(format: "%.1f km", record.value)
        case .mostElevation:
            return String(format: "%.0f m", record.value)
        case .fastestPace:
            return RunStatisticsCalculator.formatPace(record.value) + " /km"
        case .longestDuration:
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
