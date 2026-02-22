import SwiftUI

struct CheckpointCrossingBanner: View {
    let checkpoint: LiveCheckpointState
    let onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "flag.checkered")
                .font(.title3)
                .foregroundStyle(Theme.Colors.primary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(checkpoint.checkpointName)
                        .font(.subheadline.bold())
                        .foregroundStyle(Theme.Colors.label)

                    if checkpoint.hasAidStation {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                            .accessibilityLabel("Aid station")
                    }
                }

                if let delta = checkpoint.delta {
                    Text(deltaText(delta))
                        .font(.caption.bold())
                        .foregroundStyle(deltaColor(delta))
                }
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(Theme.Spacing.xs)
                    .background(Theme.Colors.secondaryLabel)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Dismiss")
            .accessibilityHint("Dismiss checkpoint banner")
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.primary.opacity(0.12))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        )
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .onAppear {
            let announcement: String
            if let delta = checkpoint.delta {
                let formatted = RunStatisticsCalculator.formatDuration(abs(delta))
                let direction = delta < 0 ? "ahead" : "behind"
                announcement = "Checkpoint \(checkpoint.checkpointName). \(formatted) \(direction)"
            } else {
                announcement = "Checkpoint \(checkpoint.checkpointName)"
            }
            AccessibilityNotification.Announcement(announcement).post()
        }
    }

    private func deltaText(_ delta: TimeInterval) -> String {
        let formatted = RunStatisticsCalculator.formatDuration(abs(delta))
        return delta < 0 ? "\(formatted) ahead" : "\(formatted) behind"
    }

    private func deltaColor(_ delta: TimeInterval) -> Color {
        delta < 0 ? Theme.Colors.success : Theme.Colors.danger
    }
}
