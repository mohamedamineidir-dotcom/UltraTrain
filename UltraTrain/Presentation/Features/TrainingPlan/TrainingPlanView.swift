import SwiftUI

struct TrainingPlanView: View {
    @State private var viewModel: TrainingPlanViewModel
    private let raceRepository: any RaceRepository
    private let planRepository: any TrainingPlanRepository

    init(
        planRepository: any TrainingPlanRepository,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        planGenerator: any GenerateTrainingPlanUseCase,
        nutritionRepository: any NutritionRepository,
        sessionNutritionAdvisor: any SessionNutritionAdvisor,
        fitnessRepository: any FitnessRepository,
        widgetDataWriter: WidgetDataWriter
    ) {
        self.raceRepository = raceRepository
        self.planRepository = planRepository
        _viewModel = State(initialValue: TrainingPlanViewModel(
            planRepository: planRepository,
            athleteRepository: athleteRepository,
            raceRepository: raceRepository,
            planGenerator: planGenerator,
            nutritionRepository: nutritionRepository,
            nutritionAdvisor: sessionNutritionAdvisor,
            fitnessRepository: fitnessRepository,
            widgetDataWriter: widgetDataWriter
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading plan...")
                } else if let plan = viewModel.plan {
                    planContent(plan)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Training Plan")
            .toolbar {
                if viewModel.plan != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: Theme.Spacing.sm) {
                            NavigationLink {
                                RaceCalendarView(
                                    plan: viewModel.plan!,
                                    races: viewModel.races
                                )
                            } label: {
                                Image(systemName: "list.bullet")
                            }

                            NavigationLink {
                                RaceCalendarGridView(
                                    raceRepository: raceRepository,
                                    planRepository: planRepository
                                )
                            } label: {
                                Image(systemName: "calendar")
                            }
                        }
                    }
                }
            }
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
        }
    }

    private func planContent(_ plan: TrainingPlan) -> some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.sm) {
                if viewModel.isPlanStale {
                    stalePlanBanner
                }

                if !viewModel.visibleRecommendations.isEmpty {
                    PlanAdjustmentBanner(
                        recommendations: viewModel.visibleRecommendations,
                        isApplying: viewModel.isApplyingAdjustment,
                        onApply: { rec in
                            Task { await viewModel.applyRecommendation(rec) }
                        },
                        onDismiss: { rec in
                            viewModel.dismissRecommendation(rec)
                        }
                    )
                }

                planHeader(plan)

                ForEach(Array(plan.weeks.enumerated()), id: \.element.id) { weekIndex, week in
                    WeekCardView(
                        week: week,
                        weekIndex: weekIndex,
                        isCurrentWeek: week.containsToday,
                        planStartDate: plan.weeks.first?.startDate ?? .now,
                        planEndDate: plan.weeks.last?.endDate ?? .now,
                        allWeeks: plan.weeks,
                        athlete: viewModel.athlete,
                        nutritionAdvisor: viewModel.nutritionAdvisor,
                        nutritionPreferences: viewModel.nutritionPreferences,
                        onToggleSession: { sessionIndex in
                            Task {
                                await viewModel.toggleSessionCompletion(
                                    weekIndex: weekIndex,
                                    sessionIndex: sessionIndex
                                )
                            }
                        },
                        onSkipSession: { sessionIndex in
                            Task {
                                await viewModel.skipSession(
                                    weekIndex: weekIndex,
                                    sessionIndex: sessionIndex
                                )
                            }
                        },
                        onUnskipSession: { sessionIndex in
                            Task {
                                await viewModel.unskipSession(
                                    weekIndex: weekIndex,
                                    sessionIndex: sessionIndex
                                )
                            }
                        },
                        onRescheduleSession: { sessionIndex, newDate in
                            Task {
                                await viewModel.rescheduleSession(
                                    weekIndex: weekIndex,
                                    sessionIndex: sessionIndex,
                                    to: newDate
                                )
                            }
                        },
                        onSwapSession: { sessionIndex, candidate in
                            Task {
                                await viewModel.swapSessions(
                                    weekIndexA: weekIndex,
                                    sessionIndexA: sessionIndex,
                                    weekIndexB: candidate.weekIndex,
                                    sessionIndexB: candidate.sessionIndex
                                )
                            }
                        },
                        onReorderSession: { sourceWeekIndex, sourceSessionIndex, target in
                            Task {
                                await viewModel.swapSessions(
                                    weekIndexA: sourceWeekIndex,
                                    sessionIndexA: sourceSessionIndex,
                                    weekIndexB: target.weekIndex,
                                    sessionIndexB: target.sessionIndex
                                )
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }

    private func planHeader(_ plan: TrainingPlan) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("\(plan.totalWeeks) weeks")
                        .font(.title2)
                        .fontWeight(.bold)
                    if let currentWeek = viewModel.currentWeek {
                        Text("Week \(currentWeek.weekNumber) — \(currentWeek.phase.displayName)")
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
                Spacer()
                let progress = viewModel.weeklyProgress
                if progress.total > 0 {
                    VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                        Text("\(progress.completed)/\(progress.total)")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("this week")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
            }
        }
        .cardStyle()
    }

    private var stalePlanBanner: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.Colors.warning)
            VStack(alignment: .leading, spacing: 2) {
                Text("Plan may be outdated")
                    .font(.subheadline.bold())
                Text(staleBannerDescription)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
            Button("Update Plan") {
                viewModel.showRegenerateConfirmation = true
            }
            .font(.caption.bold())
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var staleBannerDescription: String {
        let summary = viewModel.raceChangeSummary
        var parts: [String] = []
        if !summary.added.isEmpty {
            let names = summary.added.map(\.name).joined(separator: ", ")
            parts.append("Added: \(names)")
        }
        if !summary.removed.isEmpty {
            let count = summary.removed.count
            parts.append("Removed: \(count) race\(count == 1 ? "" : "s")")
        }
        if parts.isEmpty {
            return "Your races have changed since this plan was generated."
        }
        return parts.joined(separator: ". ") + "."
    }

    private var regenerateDialogMessage: String {
        let summary = viewModel.raceChangeSummary
        var lines: [String] = ["Your race schedule has changed."]
        if !summary.added.isEmpty {
            let names = summary.added.map(\.name).joined(separator: ", ")
            lines.append("Added: \(names)")
        }
        if !summary.removed.isEmpty {
            let count = summary.removed.count
            lines.append("Removed: \(count) race\(count == 1 ? "" : "s")")
        }
        lines.append("The plan will be regenerated with taper and recovery adjustments. Completed sessions will be preserved where possible.")
        return lines.joined(separator: "\n")
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Training Plan", systemImage: "calendar.badge.plus")
        } description: {
            Text("Generate a personalized training plan based on your profile and race goal.")
        } actions: {
            Button {
                Task { await viewModel.generatePlan() }
            } label: {
                if viewModel.isGenerating {
                    ProgressView()
                        .padding(.horizontal)
                } else {
                    Text("Generate Plan")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isGenerating)
            .accessibilityIdentifier("trainingPlan.generateButton")
        }
        .accessibilityIdentifier("trainingPlan.emptyState")
    }
}
