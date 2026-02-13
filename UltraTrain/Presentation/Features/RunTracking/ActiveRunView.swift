import SwiftUI

struct ActiveRunView: View {
    @Bindable var viewModel: ActiveRunViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            RunMapView(coordinates: viewModel.routeCoordinates)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.sm)

            Spacer().frame(height: Theme.Spacing.lg)

            timerDisplay

            Spacer().frame(height: Theme.Spacing.lg)

            ActiveRunStatsBar(
                distance: viewModel.formattedDistance,
                pace: viewModel.formattedPace,
                elevation: viewModel.formattedElevation,
                heartRate: viewModel.currentHeartRate
            )
            .padding(.horizontal, Theme.Spacing.md)

            Spacer()

            controls
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.xl)
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            if viewModel.runState == .notStarted {
                viewModel.startRun()
            }
        }
        .sheet(isPresented: $viewModel.showSummary) {
            RunSummarySheet(viewModel: viewModel) {
                dismiss()
            }
        }
    }

    // MARK: - Timer

    private var timerDisplay: some View {
        Text(viewModel.formattedTime)
            .font(.system(size: 56, weight: .bold, design: .monospaced))
            .monospacedDigit()
            .foregroundStyle(timerColor)
    }

    private var timerColor: Color {
        switch viewModel.runState {
        case .paused: Theme.Colors.warning
        case .running: Theme.Colors.label
        default: Theme.Colors.secondaryLabel
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private var controls: some View {
        switch viewModel.runState {
        case .notStarted:
            EmptyView()

        case .running:
            HStack(spacing: Theme.Spacing.xl) {
                controlButton(
                    icon: "pause.fill",
                    label: "Pause",
                    color: Theme.Colors.warning
                ) {
                    viewModel.pauseRun()
                }
            }

        case .paused:
            HStack(spacing: Theme.Spacing.xl) {
                controlButton(
                    icon: "play.fill",
                    label: "Resume",
                    color: Theme.Colors.success
                ) {
                    viewModel.resumeRun()
                }
                controlButton(
                    icon: "stop.fill",
                    label: "Stop",
                    color: Theme.Colors.danger
                ) {
                    viewModel.stopRun()
                }
            }

        case .finished:
            EmptyView()
        }
    }

    private func controlButton(
        icon: String,
        label: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.title)
                    .frame(width: 72, height: 72)
                    .foregroundStyle(.white)
                    .background(color)
                    .clipShape(Circle())
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
    }
}
