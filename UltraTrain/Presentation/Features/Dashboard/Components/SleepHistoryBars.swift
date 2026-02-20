import SwiftUI

struct SleepHistoryBars: View {
    let entries: [SleepEntry]

    private var recentEntries: [SleepEntry] {
        Array(entries.suffix(7))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Sleep — Last 7 Nights")
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(recentEntries) { entry in
                    barView(entry)
                }
            }
            .frame(height: 40)
        }
    }

    private func barView(_ entry: SleepEntry) -> some View {
        let hours = entry.totalSleepDuration / 3600
        let maxHeight: CGFloat = 40
        let fraction = min(hours / 10, 1.0)

        return VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 2)
                .fill(barColor(hours: hours))
                .frame(width: 16, height: max(4, maxHeight * fraction))
            Text(dayLabel(entry.date))
                .font(.system(size: 8))
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("\(dayLabel(entry.date)): \(String(format: "%.1f", hours)) hours")
    }

    private func barColor(hours: Double) -> Color {
        if hours >= 7 && hours <= 9 { return Theme.Colors.success }
        if hours >= 6 { return Theme.Colors.warning }
        return Theme.Colors.danger
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE"
        return String(formatter.string(from: date).prefix(2))
    }
}
