import SwiftUI

struct LiveSplitRow: View {
    let checkpoint: LiveCheckpointState
    let isNext: Bool

    var body: some View {
        HStack(spacing: 0) {
            Text(checkpoint.checkpointName)
                .font(.caption)
                .foregroundStyle(textColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(formatTime(checkpoint.predictedTime))
                .font(.caption.monospacedDigit())
                .foregroundStyle(textColor)
                .frame(width: 52, alignment: .trailing)

            Text(checkpoint.isCrossed ? formatTime(checkpoint.actualTime!) : "--:--")
                .font(.caption.monospacedDigit())
                .foregroundStyle(textColor)
                .frame(width: 52, alignment: .trailing)

            Text(deltaText)
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(deltaColor)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, Theme.Spacing.sm)
        .background(isNext ? Theme.Colors.primary.opacity(0.08) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
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
