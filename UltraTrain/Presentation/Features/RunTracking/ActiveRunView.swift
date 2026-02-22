import SwiftUI

struct ActiveRunView: View {
    @Bindable var viewModel: ActiveRunViewModel
    let exportService: any ExportServiceProtocol
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var timerFontSize: CGFloat = 56

    var body: some View {
        VStack(spacing: 0) {
            if let handler = viewModel.courseGuidanceHandler,
               let progress = handler.currentProgress {
                CourseProgressOverlay(
                    progress: progress,
                    courseRoute: handler.courseRoute,
                    nextCheckpointName: handler.nextCheckpointName,
                    nextCheckpointDistanceKm: handler.nextCheckpointDistanceKm,
                    nextCheckpointETA: handler.nextCheckpointETA,
                    isOffCourse: handler.isOffCourse
                )
            }

            RunMapView(
                coordinates: viewModel.routeCoordinates,
                checkpointLocations: viewModel.racePacingHandler.resolvedCheckpointLocations
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

            if let intervalState = viewModel.intervalHandler.currentState {
                IntervalProgressBar(state: intervalState)
                    .padding(.top, Theme.Spacing.xs)
            }

            if let zoneState = viewModel.liveZoneState {
                LiveHRZoneIndicator(
                    state: zoneState,
                    heartRate: viewModel.currentHeartRate
                )
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.xs)
            }

            if !viewModel.nutritionHandler.favoriteProducts.isEmpty {
                NutritionQuickTapBar(
                    products: viewModel.nutritionHandler.favoriteProducts,
                    totals: viewModel.nutritionHandler.liveNutritionTotals,
                    onProductTapped: { viewModel.nutritionHandler.logProduct($0, elapsedTime: viewModel.elapsedTime) }
                )
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.xs)
            }

            if viewModel.isRaceModeActive {
                LiveSplitPanel(
                    checkpoints: viewModel.racePacingHandler.liveCheckpointStates,
                    segmentPacings: viewModel.racePacingHandler.raceSegmentPacings,
                    nextCheckpoint: viewModel.racePacingHandler.nextCheckpoint,
                    distanceToNext: viewModel.racePacingHandler.distanceToNextCheckpointKm(currentDistanceKm: viewModel.distanceKm),
                    projectedFinish: viewModel.racePacingHandler.projectedFinishTime(context: .init(
                        distanceKm: viewModel.distanceKm,
                        elapsedTime: viewModel.elapsedTime,
                        runningAveragePace: 0,
                        trackPoints: []
                    ))
                )
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.sm)

                if let guidance = viewModel.racePacingHandler.racePacingGuidance {
                    RacePacingGuidancePanel(guidance: guidance)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.top, Theme.Spacing.xs)
                }
            }

            Spacer()

            controls
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.xl)
        }
        .overlay(alignment: .top) {
            if let reminder = viewModel.nutritionHandler.activeReminder {
                NutritionReminderBanner(
                    reminder: reminder,
                    onTaken: { viewModel.nutritionHandler.markTaken(elapsedTime: viewModel.elapsedTime) },
                    onSkipped: { viewModel.nutritionHandler.markSkipped(elapsedTime: viewModel.elapsedTime) },
                    onAutoDismiss: { viewModel.nutritionHandler.dismiss(elapsedTime: viewModel.elapsedTime) }
                )
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: viewModel.nutritionHandler.activeReminder)
        .overlay(alignment: .top) {
            if let crossing = viewModel.racePacingHandler.activeCrossingBanner {
                CheckpointCrossingBanner(
                    checkpoint: crossing,
                    onDismiss: { viewModel.racePacingHandler.dismissCrossingBanner() }
                )
                .padding(.top, viewModel.nutritionHandler.activeReminder != nil ? 80 : 0)
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: viewModel.racePacingHandler.activeCrossingBanner)
        .overlay(alignment: .top) {
            if let alert = viewModel.racePacingHandler.activePacingAlert {
                PacingAlertBanner(
                    alert: alert,
                    onDismiss: { viewModel.racePacingHandler.dismissPacingAlert() }
                )
                .padding(.top, pacingBannerOffset)
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: viewModel.racePacingHandler.activePacingAlert)
        .overlay(alignment: .top) {
            if let driftAlert = viewModel.activeDriftAlert {
                ZoneDriftAlertBanner(
                    alert: driftAlert,
                    onDismiss: { viewModel.dismissDriftAlert() }
                )
                .padding(.top, driftBannerOffset)
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: viewModel.activeDriftAlert)
        .overlay(alignment: .top) {
            if let transition = viewModel.intervalHandler.showPhaseTransitionBanner {
                IntervalPhaseBanner(transition: transition)
                    .padding(.top, intervalBannerOffset)
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: viewModel.intervalHandler.showPhaseTransitionBanner)
        .overlay {
            if viewModel.intervalHandler.isCountingDown {
                IntervalCountdownOverlay(seconds: viewModel.intervalHandler.countdownSeconds)
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: viewModel.intervalHandler.isCountingDown)
        .overlay {
            if let handler = viewModel.safetyHandler,
               let alert = handler.activeAlert,
               handler.isCountingDown {
                SafetyAlertBanner(
                    alert: alert,
                    countdownRemaining: handler.countdownRemaining,
                    onCancel: { handler.cancelAlert() }
                )
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: viewModel.safetyHandler?.isCountingDown)
        .overlay(alignment: .top) {
            if let handler = viewModel.courseGuidanceHandler,
               let arrived = handler.arrivedCheckpoint {
                CheckpointArrivalBanner(
                    checkpoint: arrived,
                    timeDelta: handler.arrivedCheckpointTimeDelta
                )
                .padding(.top, courseArrivalBannerOffset)
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: viewModel.courseGuidanceHandler?.arrivedCheckpoint?.id)
        .sheet(isPresented: safetyMessageBinding) {
            if let handler = viewModel.safetyHandler, MessageComposeView.canSendText {
                MessageComposeView(
                    recipients: handler.emergencyPhoneNumbers,
                    body: handler.emergencyMessage
                ) {
                    handler.showMessageCompose = false
                }
            }
        }
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
                    .accessibilityLabel("Run is auto paused")
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: viewModel.isAutoPaused)
    }

    private var pacingBannerOffset: CGFloat {
        var offset: CGFloat = 0
        if viewModel.nutritionHandler.activeReminder != nil { offset += 80 }
        if viewModel.racePacingHandler.activeCrossingBanner != nil { offset += 80 }
        return offset
    }

    private var driftBannerOffset: CGFloat {
        var offset = pacingBannerOffset
        if viewModel.racePacingHandler.activePacingAlert != nil { offset += 80 }
        return offset
    }

    private var safetyMessageBinding: Binding<Bool> {
        Binding(
            get: { viewModel.safetyHandler?.showMessageCompose ?? false },
            set: { viewModel.safetyHandler?.showMessageCompose = $0 }
        )
    }

    private var intervalBannerOffset: CGFloat {
        var offset = driftBannerOffset
        if viewModel.activeDriftAlert != nil { offset += 80 }
        return offset
    }

    private var courseArrivalBannerOffset: CGFloat {
        var offset = intervalBannerOffset
        if viewModel.intervalHandler.showPhaseTransitionBanner != nil { offset += 80 }
        return offset
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
        .accessibilityHint("Double tap to \(label.lowercased()) the run")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(accessibilityID)
    }
}
