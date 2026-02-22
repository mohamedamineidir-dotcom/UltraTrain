import SwiftUI

struct CheckpointArrivalBanner: View {
    let checkpoint: Checkpoint
    let timeDelta: TimeInterval?

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "flag.fill")
                .font(.title3)
                .foregroundStyle(bannerColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(checkpoint.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.Colors.label)

                if let delta = timeDelta {
                    Text(timeDeltaText(delta))
                        .font(.caption.bold())
                        .foregroundStyle(bannerColor)
                }
            }

            Spacer()

            if checkpoint.hasAidStation {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .accessibilityLabel("Aid station available")
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(bannerColor.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(bannerColor.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, Theme.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    // MARK: - Helpers

    private var bannerColor: Color {
        guard let delta = timeDelta else { return Theme.Colors.primary }
        if delta < 0 { return Theme.Colors.success }
        if delta > 0 { return Theme.Colors.danger }
        return Theme.Colors.primary
    }

    private func timeDeltaText(_ delta: TimeInterval) -> String {
        let absDelta = abs(delta)
        let formatted = formatTimeDelta(absDelta)

        if delta < 0 {
            return "\(formatted) ahead"
        } else if delta > 0 {
            return "\(formatted) behind"
        }
        return "On schedule"
    }

    private func formatTimeDelta(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    private var accessibilityText: String {
        var text = "Checkpoint reached: \(checkpoint.name)."
        if let delta = timeDelta {
            let formatted = formatTimeDelta(abs(delta))
            if delta < 0 {
                text += " \(formatted) ahead of plan."
            } else if delta > 0 {
                text += " \(formatted) behind plan."
            } else {
                text += " On schedule."
            }
        }
        if checkpoint.hasAidStation {
            text += " Aid station available."
        }
        return text
    }
}
