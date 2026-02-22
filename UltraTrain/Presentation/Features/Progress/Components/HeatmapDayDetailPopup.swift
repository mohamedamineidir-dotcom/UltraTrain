import SwiftUI

struct HeatmapDayDetailPopup: View {
    let day: TrainingCalendarHeatmapCalculator.DayIntensity
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(day.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.Colors.label)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                .accessibilityLabel("Close")
            }

            HStack(spacing: Theme.Spacing.md) {
                detailItem(label: "Distance", value: String(format: "%.1f km", day.totalDistanceKm))
                detailItem(label: "Duration", value: formattedDuration)
                detailItem(label: "Runs", value: "\(day.runCount)")
            }

            Text(intensityLabel)
                .font(.caption)
                .foregroundStyle(intensityColor)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(intensityColor.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(Theme.Spacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .padding(.horizontal, Theme.Spacing.lg)
    }

    // MARK: - Helpers

    private func detailItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(value)
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(Theme.Colors.label)
        }
    }

    private var formattedDuration: String {
        let hours = Int(day.totalDuration) / 3600
        let minutes = (Int(day.totalDuration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(String(format: "%02d", minutes))m"
        }
        return "\(minutes)m"
    }

    private var intensityLabel: String {
        switch day.intensity {
        case .rest: return "Rest"
        case .easy: return "Easy"
        case .moderate: return "Moderate"
        case .hard: return "Hard"
        case .veryHard: return "Very Hard"
        }
    }

    private var intensityColor: Color {
        switch day.intensity {
        case .rest: return Theme.Colors.secondaryLabel
        case .easy: return Theme.Colors.success
        case .moderate: return Theme.Colors.warning
        case .hard: return Theme.Colors.danger
        case .veryHard: return Theme.Colors.danger
        }
    }
}
