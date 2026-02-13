import SwiftUI

struct TrainingPlanView: View {
    @State private var viewModel: TrainingPlanViewModel

    init(
        planRepository: any TrainingPlanRepository,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        planGenerator: any GenerateTrainingPlanUseCase
    ) {
        _viewModel = State(initialValue: TrainingPlanViewModel(
            planRepository: planRepository,
            athleteRepository: athleteRepository,
            raceRepository: raceRepository,
            planGenerator: planGenerator
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
                        NavigationLink {
                            RaceCalendarView(
                                plan: viewModel.plan!,
                                races: viewModel.races
                            )
                        } label: {
                            Image(systemName: "calendar")
                        }
                    }
                }
            }
            .task {
                await viewModel.loadPlan()
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }

    private func planContent(_ plan: TrainingPlan) -> some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.sm) {
                if viewModel.isPlanStale {
                    stalePlanBanner
                }

                planHeader(plan)

                ForEach(Array(plan.weeks.enumerated()), id: \.element.id) { weekIndex, week in
                    WeekCardView(
                        week: week,
                        weekIndex: weekIndex,
                        isCurrentWeek: week.containsToday
                    ) { sessionIndex in
                        Task {
                            await viewModel.toggleSessionCompletion(
                                weekIndex: weekIndex,
                                sessionIndex: sessionIndex
                            )
                        }
                    }
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
                Text("Your races have changed since this plan was generated.")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
            Button("Regenerate") {
                Task { await viewModel.generatePlan() }
            }
            .font(.caption.bold())
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
        }
    }
}
