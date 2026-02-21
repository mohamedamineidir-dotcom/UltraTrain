import SwiftUI

struct LiveHRTimeInZoneBars: View {
    let zoneDistribution: [Int: TimeInterval]
    let targetZone: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Time in Zones")
                .font(.headline)

            ForEach(1...5, id: \.self) { zone in
                zoneRow(zone: zone)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Zone Row

    private func zoneRow(zone: Int) -> some View {
        let seconds = zoneDistribution[zone, default: 0]
        let fraction = totalSeconds > 0 ? seconds / totalSeconds : 0

        return HStack(spacing: Theme.Spacing.sm) {
            Text("Z\(zone)")
                .font(.caption.bold().monospacedDigit())
                .frame(width: 24, alignment: .leading)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 14)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(zoneColor(zone))
                        .frame(width: max(0, geometry.size.width * fraction), height: 14)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(zoneColor(zone), lineWidth: targetZone == zone ? 2 : 0)
                        .frame(height: 14)
                )
            }
            .frame(height: 14)

            Text(formatTime(seconds))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 40, alignment: .trailing)
        }
    }

    // MARK: - Helpers

    private var totalSeconds: TimeInterval {
        zoneDistribution.values.reduce(0, +)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func zoneColor(_ zone: Int) -> Color {
        switch zone {
        case 1: .blue
        case 2: .green
        case 3: .yellow
        case 4: .orange
        case 5: .red
        default: .gray
        }
    }

    private var accessibilitySummary: String {
        let entries = (1...5).map { zone in
            "Zone \(zone): \(formatTime(zoneDistribution[zone, default: 0]))"
        }.joined(separator: ", ")
        return "Time in zones. \(entries)"
    }
}
