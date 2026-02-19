import SwiftUI

struct LastRunCard: View {
    let lastRun: CompletedRun?

    var body: some View {
        if let run = lastRun {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Last Run")
                    .font(.headline)

                HStack(spacing: Theme.Spacing.md) {
                    statColumn(value: String(format: "%.1f", run.distanceKm), label: "km")
                    statColumn(value: run.paceFormatted, label: "pace")
                    statColumn(value: formattedDuration(run.duration), label: "time")
                }

                Text(relativeDateString(run.date))
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private func relativeDateString(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date.startOfDay, to: Date.now.startOfDay).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        if days < 7 { return "\(days) days ago" }
        return date.formatted(.dateTime.month().day())
    }
}
