import SwiftUI

struct WatchStandaloneRunView: View {
    let viewModel: WatchRunViewModel
    let onStop: () -> Void

    @Environment(\.isLuminanceReduced) var isLuminanceReduced

    var body: some View {
        TabView {
            metricsPage
            if !isLuminanceReduced {
                controlsPage
                WatchSplitsPage(splits: viewModel.splits)
            }
        }
        .tabViewStyle(.verticalPage)
        .overlay(alignment: .top) {
            if !isLuminanceReduced {
                bannerOverlay
            }
        }
    }

    // MARK: - Banner Overlay

    @ViewBuilder
    private var bannerOverlay: some View {
        if let split = viewModel.latestSplit {
            WatchSplitBanner(
                split: split,
                previousPace: previousSplitPace(before: split)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
            .padding(.horizontal, 4)
            .padding(.top, 2)
        } else if viewModel.activeReminder != nil {
            WatchNutritionBanner(
                message: viewModel.activeReminder?.message ?? "",
                reminderType: viewModel.activeReminder?.type.rawValue,
                onDismiss: { viewModel.dismissReminder() }
            )
        }
    }

    // MARK: - Page 1: Metrics

    private var metricsPage: some View {
        VStack(spacing: 4) {
            stateBadge
            Text(viewModel.formattedTime)
                .font(.system(.title, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)
                .opacity(isLuminanceReduced ? 0.6 : 1.0)

            HStack(spacing: 16) {
                metricColumn(value: viewModel.formattedDistance, unit: "km", icon: "figure.run")
                if !isLuminanceReduced {
                    metricColumn(value: viewModel.currentPace, unit: "/km", icon: "speedometer")
                }
            }
            .opacity(isLuminanceReduced ? 0.6 : 1.0)

            if !isLuminanceReduced {
                HStack(spacing: 16) {
                    if let hr = viewModel.currentHeartRate {
                        metricColumn(value: "\(hr)", unit: "bpm", icon: "heart.fill")
                            .foregroundStyle(hrZoneColor)
                    }
                    metricColumn(value: viewModel.formattedElevation, unit: "", icon: "mountain.2.fill")
                }
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

    // MARK: - HR Zone Color

    private var hrZoneColor: Color {
        guard let zone = viewModel.currentHRZone else { return .white }
        switch zone {
        case 1: return .green
        case 2: return .blue
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .white
        }
    }

    // MARK: - Split Helpers

    private func previousSplitPace(before split: WatchSplit) -> Double? {
        guard split.kilometerNumber > 1 else { return nil }
        return viewModel.splits.first(where: {
            $0.kilometerNumber == split.kilometerNumber - 1
        })?.duration
    }
}
