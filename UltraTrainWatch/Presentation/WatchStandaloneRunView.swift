import SwiftUI

struct WatchStandaloneRunView: View {
    let viewModel: WatchRunViewModel
    let onStop: () -> Void

    var body: some View {
        TabView {
            metricsPage
            controlsPage
        }
        .tabViewStyle(.verticalPage)
        .overlay(alignment: .top) {
            if viewModel.activeReminder != nil {
                WatchNutritionBanner(
                    message: viewModel.activeReminder?.message ?? "",
                    reminderType: viewModel.activeReminder?.type.rawValue,
                    onDismiss: { viewModel.dismissReminder() }
                )
            }
        }
    }

    // MARK: - Page 1: Metrics

    private var metricsPage: some View {
        VStack(spacing: 4) {
            stateBadge
            Text(viewModel.formattedTime)
                .font(.system(.title, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)

            HStack(spacing: 16) {
                metricColumn(value: viewModel.formattedDistance, unit: "km", icon: "figure.run")
                metricColumn(value: viewModel.currentPace, unit: "/km", icon: "speedometer")
            }

            HStack(spacing: 16) {
                if let hr = viewModel.currentHeartRate {
                    metricColumn(value: "\(hr)", unit: "bpm", icon: "heart.fill")
                }
                metricColumn(value: viewModel.formattedElevation, unit: "", icon: "mountain.2.fill")
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Page 2: Controls

    private var controlsPage: some View {
        VStack(spacing: 12) {
            if viewModel.runState == .paused {
                Button {
                    viewModel.resumeRun()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.green)
            } else {
                Button {
                    viewModel.pauseRun()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.yellow)
            }

            Button(role: .destructive) {
                onStop()
            } label: {
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
        if viewModel.isAutoPaused { return "Auto-paused" }
        switch viewModel.runState {
        case .running: return "Running"
        case .paused: return "Paused"
        default: return ""
        }
    }

    private var stateColor: Color {
        if viewModel.isAutoPaused { return .orange }
        switch viewModel.runState {
        case .running: return .green
        case .paused: return .yellow
        default: return .secondary
        }
    }
}
