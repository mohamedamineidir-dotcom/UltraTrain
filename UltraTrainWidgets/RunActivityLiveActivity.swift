import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct RunActivityLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RunActivityAttributes.self) { context in
            RunActivityLockScreenView(
                state: context.state,
                startTime: context.attributes.startTime
            )
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    timerView(state: context.state)
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                }

                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(context.state.formattedDistance + " km", systemImage: "location.fill")
                            .font(.caption)
                        Label(context.state.formattedElevation, systemImage: "mountain.2.fill")
                            .font(.caption)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Label(context.state.formattedPace + " /km", systemImage: "speedometer")
                            .font(.caption)
                        if let hr = context.state.currentHeartRate {
                            Label("\(hr) bpm", systemImage: "heart.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        expandedBottomControl(for: context.state)
                        if let checkpoint = context.state.nextCheckpointName {
                            HStack(spacing: 4) {
                                Image(systemName: "flag.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                                Text(checkpoint)
                                    .font(.caption2)
                                    .foregroundStyle(.white)
                                if let dist = context.state.distanceToCheckpointKm {
                                    Text(String(format: "%.1f km", dist))
                                        .font(.caption2.bold().monospacedDigit())
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: stateIcon(for: context.state.runState))
                    .foregroundStyle(stateColor(for: context.state.runState))
            } compactTrailing: {
                compactTrailingContent(for: context.state)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: stateIcon(for: context.state.runState))
                    .foregroundStyle(stateColor(for: context.state.runState))
            }
        }
    }

    // MARK: - Expanded Bottom Control

    @ViewBuilder
    private func expandedBottomControl(
        for state: RunActivityAttributes.ContentState
    ) -> some View {
        switch state.runState {
        case "running":
            Button(intent: PauseRunIntent()) {
                HStack(spacing: 4) {
                    Image(systemName: "pause.fill")
                    Text("Pause")
                }
                .font(.caption.bold())
            }
            .tint(.orange)
        case "paused", "autoPaused":
            Button(intent: ResumeRunIntent()) {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                    Text("Resume")
                }
                .font(.caption.bold())
            }
            .tint(.green)
        default:
            HStack {
                Image(systemName: stateIcon(for: state.runState))
                Text(stateLabel(for: state.runState, isAutoPaused: state.isAutoPaused))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .textCase(.uppercase)
            }
            .foregroundStyle(stateColor(for: state.runState))
        }
    }

    // MARK: - Compact Trailing

    @ViewBuilder
    private func compactTrailingContent(
        for state: RunActivityAttributes.ContentState
    ) -> some View {
        if let dist = state.distanceToCheckpointKm, state.nextCheckpointName != nil {
            Text(String(format: "%.1f km → CP", dist))
        } else {
            Text(state.formattedDistance + " km")
        }
    }

    // MARK: - Timer View

    @ViewBuilder
    private func timerView(state: RunActivityAttributes.ContentState) -> some View {
        if state.isPaused {
            Text(formatDuration(state.elapsedTime))
        } else {
            Text(timerInterval: state.timerStartDate...Date.distantFuture, countsDown: false)
        }
    }

    // MARK: - Helpers

    private func stateIcon(for runState: String) -> String {
        switch runState {
        case "running": "figure.run"
        case "paused", "autoPaused": "pause.fill"
        case "finished": "flag.checkered"
        default: "figure.run"
        }
    }

    private func stateColor(for runState: String) -> Color {
        switch runState {
        case "running": .green
        case "paused", "autoPaused": .orange
        case "finished": .blue
        default: .green
        }
    }

    private func stateLabel(for runState: String, isAutoPaused: Bool) -> String {
        switch runState {
        case "running": "Running"
        case "paused": isAutoPaused ? "Auto-paused" : "Paused"
        case "autoPaused": "Auto-paused"
        case "finished": "Finished"
        default: "Running"
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d:%02d", hours, minutes, secs)
    }
}
