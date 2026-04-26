import SwiftUI

struct TrainingPlanView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State var viewModel: TrainingPlanViewModel
    /// #30: export flow state. The confirmation dialog picks the
    /// format, then we populate `exportedFileURL` to trigger the
    /// share sheet. Both states reset on dismiss so subsequent
    /// exports work cleanly.
    @State private var showExportDialog = false
    @State private var exportedFileURL: URL?
    @State private var exportError: String?
    @State private var showPauseSheet = false
    private let raceRepository: any RaceRepository
    private let planRepository: any TrainingPlanRepository
    private let workoutRecipeRepository: any WorkoutRecipeRepository
    private let runRepository: any RunRepository
    private let athleteRepository: any AthleteRepository
    private let subscriptionService: (any SubscriptionServiceProtocol)?
    private let stravaAuthService: (any StravaAuthServiceProtocol)?
    private let stravaImportService: (any StravaImportServiceProtocol)?

    init(
        planRepository: any TrainingPlanRepository,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        planGenerator: any GenerateTrainingPlanUseCase,
        nutritionRepository: any NutritionRepository,
        sessionNutritionAdvisor: any SessionNutritionAdvisor,
        fitnessRepository: any FitnessRepository,
        widgetDataWriter: WidgetDataWriter,
        workoutRecipeRepository: any WorkoutRecipeRepository,
        runRepository: any RunRepository,
        hapticService: any HapticServiceProtocol = HapticService(),
        subscriptionService: (any SubscriptionServiceProtocol)? = nil,
        stravaAuthService: (any StravaAuthServiceProtocol)? = nil,
        stravaImportService: (any StravaImportServiceProtocol)? = nil,
        intervalPerformanceRepository: (any IntervalPerformanceRepository)? = nil,
        notificationService: (any NotificationServiceProtocol)? = nil,
        appSettingsRepository: (any AppSettingsRepository)? = nil,
        recoveryRepository: (any RecoveryRepository)? = nil
    ) {
        self.raceRepository = raceRepository
        self.planRepository = planRepository
        self.workoutRecipeRepository = workoutRecipeRepository
        self.runRepository = runRepository
        self.athleteRepository = athleteRepository
        self.subscriptionService = subscriptionService
        self.stravaAuthService = stravaAuthService
        self.stravaImportService = stravaImportService
        _viewModel = State(initialValue: TrainingPlanViewModel(
            planRepository: planRepository,
            athleteRepository: athleteRepository,
            raceRepository: raceRepository,
            planGenerator: planGenerator,
            nutritionRepository: nutritionRepository,
            nutritionAdvisor: sessionNutritionAdvisor,
            fitnessRepository: fitnessRepository,
            widgetDataWriter: widgetDataWriter,
            hapticService: hapticService,
            subscriptionService: subscriptionService,
            runRepository: runRepository,
            stravaAuthService: stravaAuthService,
            stravaImportService: stravaImportService,
            intervalPerformanceRepository: intervalPerformanceRepository,
            notificationService: notificationService,
            appSettingsRepository: appSettingsRepository,
            recoveryRepository: recoveryRepository
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isGenerating {
                    PlanGenerationLoadingView()
                } else if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let plan = viewModel.plan {
                    planContent(plan)
                } else {
                    emptyState
                }
            }
            .background(Theme.Gradients.futuristicBackground(colorScheme: colorScheme).ignoresSafeArea())
            .navigationTitle("Training Plan")
            .toolbar {
                if viewModel.plan != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: Theme.Spacing.sm) {
                            NavigationLink {
                                WorkoutLibraryView(
                                    recipeRepository: workoutRecipeRepository,
                                    planRepository: planRepository
                                )
                            } label: {
                                Image(systemName: "book.fill")
                            }
                            .accessibilityLabel("Workout library")

                            NavigationLink {
                                TrainingCalendarView(
                                    planRepository: planRepository,
                                    runRepository: runRepository,
                                    athleteRepository: athleteRepository
                                )
                            } label: {
                                Image(systemName: "calendar.badge.checkmark")
                            }
                            .accessibilityLabel("Training calendar")

                            if let plan = viewModel.plan {
                                NavigationLink {
                                    RaceCalendarView(
                                        plan: plan,
                                        races: viewModel.races
                                    )
                                } label: {
                                    Image(systemName: "list.bullet")
                                }
                                .accessibilityLabel("Race calendar list")
                            }

                            // Pause training — illness or injury.
                            // Triggers suspendTraining or
                            // reportMidCycleInjury via the sheet.
                            // The most-coach-relevant button on this
                            // toolbar — sits between the navigation
                            // helpers and export so it's always one tap
                            // away when the athlete needs it.
                            Button {
                                showPauseSheet = true
                            } label: {
                                Image(systemName: "pause.circle")
                            }
                            .accessibilityLabel("Pause training")
                            .accessibilityIdentifier("trainingPlan.pauseButton")

                            // #30: plan export (PDF + calendar).
                            // Respects the subscription gate — hands
                            // off viewModel.visibleWeeks, not the full
                            // plan.weeks, so locked weeks are never
                            // leaked to the exported file.
                            Button {
                                showExportDialog = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                            .accessibilityLabel("Export plan")

                            NavigationLink {
                                RaceCalendarGridView(
                                    raceRepository: raceRepository,
                                    planRepository: planRepository
                                )
                            } label: {
                                Image(systemName: "calendar")
                            }
                            .accessibilityLabel("Race calendar grid")
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isGenerating)
            .task {
                await viewModel.loadPlan()
            }
            .onAppear {
                Task { await viewModel.refreshRaces() }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .confirmationDialog(
                "Update Training Plan",
                isPresented: $viewModel.showRegenerateConfirmation,
                titleVisibility: .visible
            ) {
                Button("Update Plan") {
                    Task { await viewModel.generatePlan() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(regenerateDialogMessage)
            }
            .confirmationDialog(
                "Export Plan",
                isPresented: $showExportDialog,
                titleVisibility: .visible
            ) {
                Button("Save as PDF") { exportPlan(as: .pdf) }
                Button("Add to Calendar (.ics)") { exportPlan(as: .ics) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(exportDialogMessage)
            }
            .sheet(item: Binding(
                get: { exportedFileURL.map { ExportFile(url: $0) } },
                set: { exportedFileURL = $0?.url }
            )) { file in
                ShareSheet(activityItems: [file.url])
            }
            .alert("Export Failed", isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("OK") { exportError = nil }
            } message: {
                Text(exportError ?? "")
            }
            .sheet(isPresented: $showPauseSheet) {
                PauseTrainingSheet(
                    onSuspend: { days, reason in
                        await viewModel.suspendTraining(forDays: days, reason: reason)
                    },
                    onReportInjury: { days, bumpPain in
                        await viewModel.reportMidCycleInjury(
                            suspendDays: days,
                            bumpPainFrequencyToOften: bumpPain
                        )
                    }
                )
            }
        }
    }

    private var exportDialogMessage: String {
        if viewModel.hasLockedWeeks {
            return "Only your \(viewModel.visibleWeeks.count) visible weeks will be exported. Upgrade to export the full plan."
        }
        return "Export all \(viewModel.visibleWeeks.count) weeks of your training plan."
    }

    private enum ExportFormat { case pdf, ics }

    private func exportPlan(as format: ExportFormat) {
        guard viewModel.plan != nil else { return }
        let visible = viewModel.visibleWeeks
        let lockedCount = viewModel.lockedWeekCount
        let hasLocked = viewModel.hasLockedWeeks
        let raceName = viewModel.targetRace?.name ?? "Untitled Race"
        let raceDate = viewModel.targetRace?.date
        do {
            let url: URL
            switch format {
            case .pdf:
                url = try PlanPdfExporter.export(
                    planName: "UltraTrain Plan",
                    raceName: raceName,
                    raceDate: raceDate,
                    visibleWeeks: visible,
                    hasLockedWeeks: hasLocked,
                    lockedWeekCount: lockedCount
                )
            case .ics:
                url = try PlanICSExporter.export(
                    planName: "UltraTrain — \(raceName)",
                    visibleWeeks: visible,
                    hasLockedWeeks: hasLocked
                )
            }
            exportedFileURL = url
        } catch {
            exportError = error.localizedDescription
        }
    }
}

/// Identifiable wrapper so the share sheet can be presented via
/// `.sheet(item:)` without inventing a new state for every export.
private struct ExportFile: Identifiable {
    let url: URL
    var id: URL { url }
}
