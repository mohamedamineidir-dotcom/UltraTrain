import SwiftUI

// MARK: - Timer, Banner Offsets & Controls

extension ActiveRunView {

    // MARK: - Timer

    var timerDisplay: some View {
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
                    .accessibilityLabel("Run is auto paused")
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: viewModel.isAutoPaused)
    }

    // MARK: - Banner Offsets

    var pacingBannerOffset: CGFloat {
        var offset: CGFloat = 0
        if viewModel.nutritionHandler.activeReminder != nil { offset += 80 }
        if viewModel.racePacingHandler.activeCrossingBanner != nil { offset += 80 }
        return offset
    }

    var driftBannerOffset: CGFloat {
        var offset = pacingBannerOffset
        if viewModel.racePacingHandler.activePacingAlert != nil { offset += 80 }
        return offset
    }

    var safetyMessageBinding: Binding<Bool> {
        Binding(
            get: { viewModel.safetyHandler?.showMessageCompose ?? false },
            set: { viewModel.safetyHandler?.showMessageCompose = $0 }
        )
    }

    var intervalBannerOffset: CGFloat {
        var offset = driftBannerOffset
        if viewModel.activeDriftAlert != nil { offset += 80 }
        return offset
    }

    var courseArrivalBannerOffset: CGFloat {
        var offset = intervalBannerOffset
        if viewModel.intervalHandler.showPhaseTransitionBanner != nil { offset += 80 }
        return offset
    }

    var timerColor: Color {
        switch viewModel.runState {
        case .paused: Theme.Colors.warning
        case .running: Theme.Colors.label
        default: Theme.Colors.secondaryLabel
        }
    }

    // MARK: - Controls

    @ViewBuilder
    var controls: some View {
        switch viewModel.runState {
        case .notStarted:
            EmptyView()

        case .running:
            HStack(spacing: Theme.Spacing.xl) {
                if viewModel.safetyHandler?.isActive == true {
                    SOSButton {
                        viewModel.triggerSOS()
                    }
                }
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

    func controlButton(
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
        .accessibilityHint("Double tap to \(label.lowercased()) the run")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(accessibilityID)
    }
}
