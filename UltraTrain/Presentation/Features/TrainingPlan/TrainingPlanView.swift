import SwiftUI

struct TrainingPlanView: View {
    @State var viewModel: TrainingPlanViewModel
    private let raceRepository: any RaceRepository
    private let planRepository: any TrainingPlanRepository
    private let workoutRecipeRepository: any WorkoutRecipeRepository
    private let runRepository: any RunRepository
    private let athleteRepository: any AthleteRepository

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
        runRepository: any RunRepository
    ) {
        self.raceRepository = raceRepository
        self.planRepository = planRepository
        self.workoutRecipeRepository = workoutRecipeRepository
        self.runRepository = runRepository
        self.athleteRepository = athleteRepository
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

                            NavigationLink {
                                RaceCalendarView(
                                    plan: viewModel.plan!,
                                    races: viewModel.races
                                )
                            } label: {
                                Image(systemName: "list.bullet")
                            }
                            .accessibilityLabel("Race calendar list")

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
}
