import SwiftUI
import WidgetKit

struct RunActivityLockScreenView: View {

    let state: RunActivityAttributes.ContentState
    let startTime: Date

    var body: some View {
        VStack(spacing: 12) {
            headerRow
            metricsGrid
        }
        .padding(16)
        .activityBackgroundTint(.black.opacity(0.75))
        .activitySystemActionForegroundColor(.white)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Image(systemName: stateIcon)
                .foregroundStyle(stateColor)

            timerView
                .font(.system(.title, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            stateBadge
        }
    }

    // MARK: - Timer

    @ViewBuilder
    private var timerView: some View {
        if state.isPaused {
            Text(formatDuration(state.elapsedTime))
        } else {
            Text(timerInterval: state.timerStartDate...Date.distantFuture, countsDown: false)
        }
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                metricCell(label: "Distance", value: state.formattedDistance + " km", icon: "location.fill")
                metricCell(label: "Elevation", value: state.formattedElevation, icon: "mountain.2.fill")
            }
            VStack(spacing: 8) {
                metricCell(label: "Pace", value: state.formattedPace + " /km", icon: "speedometer")
                heartRateCell
            }
        }
    }

    private func metricCell(label: String, value: String, icon: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            Spacer()
        }
    }

    private var heartRateCell: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Heart Rate")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let hr = state.currentHeartRate {
                    Text("\(hr) bpm")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundStyle(.red)
                } else {
                    Text("--")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    // MARK: - State Badge

    private var stateBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(stateColor)
                .frame(width: 6, height: 6)
            Text(stateLabel)
                .font(.caption2)
                .fontWeight(.medium)
                .textCase(.uppercase)
        }
        .foregroundStyle(stateColor)
    }

    // MARK: - Helpers

    private var stateIcon: String {
        switch state.runState {
        case "running": "figure.run"
        case "paused", "autoPaused": "pause.fill"
        case "finished": "flag.checkered"
        default: "figure.run"
        }
    }

    private var stateColor: Color {
        switch state.runState {
        case "running": .green
        case "paused", "autoPaused": .orange
        case "finished": .blue
        default: .green
        }
    }

    private var stateLabel: String {
        switch state.runState {
        case "running": "Running"
        case "paused": state.isAutoPaused ? "Auto-paused" : "Paused"
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
