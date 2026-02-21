import SwiftUI

struct LiveSplitRow: View {
    @Environment(\.unitPreference) private var units
    let checkpoint: LiveCheckpointState
    let isNext: Bool
    var targetPaceSecondsPerKm: Double?

    var body: some View {
        HStack(spacing: 0) {
            Text(checkpoint.checkpointName)
                .font(.caption)
                .foregroundStyle(textColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(formattedTargetPace)
                .font(.caption.monospacedDigit())
                .foregroundStyle(textColor)
                .frame(width: 44, alignment: .trailing)

            Text(formatTime(checkpoint.predictedTime))
                .font(.caption.monospacedDigit())
                .foregroundStyle(textColor)
                .frame(width: 52, alignment: .trailing)

            Text(deltaText)
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(deltaColor)
                .frame(width: 52, alignment: .trailing)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, Theme.Spacing.sm)
        .background(isNext ? Theme.Colors.primary.opacity(0.08) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var formattedTargetPace: String {
        guard let pace = targetPaceSecondsPerKm else { return "--" }
        return RunStatisticsCalculator.formatPace(pace, unit: units)
    }

    private var accessibilityDescription: String {
        let predicted = formatTime(checkpoint.predictedTime)
        if checkpoint.isCrossed, let actual = checkpoint.actualTime {
            let actualStr = formatTime(actual)
            let deltaStr = accessibilityDelta
            return "\(checkpoint.checkpointName). Predicted \(predicted). Actual \(actualStr). \(deltaStr)"
        }
        if isNext {
            return "\(checkpoint.checkpointName). Predicted \(predicted). Next checkpoint"
        }
        return "\(checkpoint.checkpointName). Predicted \(predicted)"
    }

    private var accessibilityDelta: String {
        guard let delta = checkpoint.delta else { return "" }
        let time = formatTime(abs(delta))
        return delta < 0 ? "Ahead by \(time)" : "Behind by \(time)"
    }

    private var textColor: Color {
        if checkpoint.isCrossed { return Theme.Colors.label }
        if isNext { return Theme.Colors.label }
        return Theme.Colors.secondaryLabel.opacity(0.6)
    }

    private var deltaText: String {
        guard let delta = checkpoint.delta else {
            return isNext ? "next" : ""
        }
        let formatted = formatTime(abs(delta))
        return delta < 0 ? "-\(formatted)" : "+\(formatted)"
    }

    private var deltaColor: Color {
        guard let delta = checkpoint.delta else {
            return isNext ? Theme.Colors.primary : Theme.Colors.secondaryLabel
        }
        return delta < 0 ? Theme.Colors.success : Theme.Colors.danger
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        }
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
