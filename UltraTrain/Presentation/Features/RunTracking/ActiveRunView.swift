import SwiftUI

struct ActiveRunView: View {
    @Bindable var viewModel: ActiveRunViewModel
    let exportService: any ExportServiceProtocol
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var timerFontSize: CGFloat = 56

    var body: some View {
        VStack(spacing: 0) {
            RunMapView(
                coordinates: viewModel.routeCoordinates,
                checkpointLocations: viewModel.resolvedCheckpointLocations
            )
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
        .overlay(alignment: .top) {
            if let reminder = viewModel.activeReminder {
                NutritionReminderBanner(reminder: reminder) {
                    viewModel.dismissReminder()
                }
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: viewModel.activeReminder)
        .navigationBarBackButtonHidden()
        .onAppear {
            if viewModel.runState == .notStarted {
                viewModel.startRun()
            }
        }
        .sheet(isPresented: $viewModel.showSummary) {
            RunSummarySheet(viewModel: viewModel, exportService: exportService) {
                dismiss()
            }
        }
    }

    // MARK: - Timer

    private var timerDisplay: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(viewModel.formattedTime)
                .font(.system(size: timerFontSize, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(timerColor)
                .accessibilityIdentifier("runTracking.timerDisplay")
                .accessibilityLabel("Elapsed time, \(viewModel.formattedTime)")

            if viewModel.isAutoPaused {
                Text("Auto-Paused")
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.Colors.warning)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: viewModel.isAutoPaused)
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
                    color: Theme.Colors.warning,
                    accessibilityID: "runTracking.pauseButton"
                ) {
                    viewModel.pauseRun()
                }
            }

        case .paused:
            HStack(spacing: Theme.Spacing.xl) {
                controlButton(
                    icon: "play.fill",
                    label: "Resume",
                    color: Theme.Colors.success,
                    accessibilityID: "runTracking.resumeButton"
                ) {
                    viewModel.resumeRun()
                }
                controlButton(
                    icon: "stop.fill",
                    label: "Stop",
                    color: Theme.Colors.danger,
                    accessibilityID: "runTracking.stopButton"
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
        accessibilityID: String,
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(accessibilityID)
    }
}
