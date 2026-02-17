import SwiftUI

struct WatchActiveRunView: View {
    let runData: WatchRunData
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void
    let onDismissReminder: () -> Void

    var body: some View {
        TabView {
            metricsPage
            controlsPage
        }
        .tabViewStyle(.verticalPage)
        .overlay(alignment: .top) {
            if runData.activeReminderMessage != nil {
                WatchNutritionBanner(
                    message: runData.activeReminderMessage ?? "",
                    reminderType: runData.activeReminderType,
                    onDismiss: onDismissReminder
                )
            }
        }
    }

    // MARK: - Page 1: Metrics

    private var metricsPage: some View {
        VStack(spacing: 4) {
            stateBadge
            Text(runData.formattedTime)
                .font(.system(.title, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)

            HStack(spacing: 16) {
                metricColumn(value: runData.formattedDistance, unit: "km", icon: "figure.run")
                metricColumn(value: runData.currentPace, unit: "/km", icon: "speedometer")
            }

            HStack(spacing: 16) {
                if let hr = runData.currentHeartRate {
                    metricColumn(value: "\(hr)", unit: "bpm", icon: "heart.fill")
                }
                metricColumn(value: runData.formattedElevation, unit: "", icon: "mountain.2.fill")
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Page 2: Controls

    private var controlsPage: some View {
        VStack(spacing: 12) {
            if runData.runState == "paused" || runData.isAutoPaused {
                Button(action: onResume) {
                    Label("Resume", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.green)
            } else {
                Button(action: onPause) {
                    Label("Pause", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.yellow)
            }

            Button(role: .destructive, action: onStop) {
                Label("Stop", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Components

    private var stateBadge: some View {
        Text(stateLabel)
            .font(.caption2)
            .foregroundStyle(stateColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(stateColor.opacity(0.2))
            .clipShape(Capsule())
    }

    private func metricColumn(value: String, unit: String, icon: String) -> some View {
        VStack(spacing: 0) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.body, design: .monospaced, weight: .semibold))
                .foregroundStyle(.white)
            if !unit.isEmpty {
                Text(unit)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var stateLabel: String {
        if runData.isAutoPaused { return "Auto-paused" }
        switch runData.runState {
        case "running": return "Running"
        case "paused": return "Paused"
        default: return runData.runState.capitalized
        }
    }

    private var stateColor: Color {
        if runData.isAutoPaused { return .orange }
        switch runData.runState {
        case "running": return .green
        case "paused": return .yellow
        default: return .secondary
        }
    }
}
