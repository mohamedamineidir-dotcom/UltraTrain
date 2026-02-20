import SwiftUI

struct LiveSplitPanel: View {
    let checkpoints: [LiveCheckpointState]
    let nextCheckpoint: LiveCheckpointState?
    let distanceToNext: Double?
    let projectedFinish: TimeInterval?

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            header
            Divider()
            splitList
            if let projectedFinish {
                projectedFinishRow(projectedFinish)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    private var header: some View {
        HStack(spacing: 0) {
            Text("Checkpoint")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Est.")
                .frame(width: 52, alignment: .trailing)
            Text("Actual")
                .frame(width: 52, alignment: .trailing)
            Text("Delta")
                .frame(width: 60, alignment: .trailing)
        }
        .font(.caption2.bold())
        .foregroundStyle(Theme.Colors.secondaryLabel)
        .padding(.horizontal, Theme.Spacing.sm)
    }

    private var splitList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(checkpoints) { checkpoint in
                    LiveSplitRow(
                        checkpoint: checkpoint,
                        isNext: checkpoint.id == nextCheckpoint?.id
                    )
                }
            }
        }
        .frame(maxHeight: 120)
    }

    private func projectedFinishRow(_ time: TimeInterval) -> some View {
        HStack {
            Image(systemName: "flag.fill")
                .font(.caption2)
                .foregroundStyle(Theme.Colors.primary)
                .accessibilityHidden(true)
            Text("Projected Finish")
                .font(.caption.bold())
                .foregroundStyle(Theme.Colors.label)
            Spacer()
            Text(FinishEstimate.formatDuration(time))
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(Theme.Colors.primary)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.top, Theme.Spacing.xs)
    }
}
