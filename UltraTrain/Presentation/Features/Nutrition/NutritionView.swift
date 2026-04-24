import SwiftUI

struct NutritionView: View {
    @State private var viewModel: NutritionViewModel

    private let athleteRepository: any AthleteRepository
    private let planRepository: any TrainingPlanRepository
    private let nutritionRepository: any NutritionRepository
    private let foodLogRepository: any FoodLogRepository
    private let sessionNutritionAdvisor: any SessionNutritionAdvisor
    private let foodDatabaseService: (any FoodDatabaseServiceProtocol)?
    private let foodPhotoAnalysisService: (any FoodPhotoAnalysisServiceProtocol)?

    init(
        nutritionRepository: any NutritionRepository,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        planRepository: any TrainingPlanRepository,
        nutritionGenerator: any GenerateNutritionPlanUseCase,
        foodLogRepository: any FoodLogRepository,
        sessionNutritionAdvisor: any SessionNutritionAdvisor,
        foodDatabaseService: (any FoodDatabaseServiceProtocol)? = nil,
        foodPhotoAnalysisService: (any FoodPhotoAnalysisServiceProtocol)? = nil
    ) {
        self.athleteRepository = athleteRepository
        self.planRepository = planRepository
        self.nutritionRepository = nutritionRepository
        self.foodLogRepository = foodLogRepository
        self.sessionNutritionAdvisor = sessionNutritionAdvisor
        self.foodDatabaseService = foodDatabaseService
        self.foodPhotoAnalysisService = foodPhotoAnalysisService

        _viewModel = State(initialValue: NutritionViewModel(
            nutritionRepository: nutritionRepository,
            athleteRepository: athleteRepository,
            raceRepository: raceRepository,
            planRepository: planRepository,
            nutritionGenerator: nutritionGenerator
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tabPicker

                Group {
                    switch viewModel.selectedTab {
                    case .training:
                        TrainingNutritionView(
                            athleteRepository: athleteRepository,
                            planRepository: planRepository,
                            nutritionRepository: nutritionRepository,
                            foodLogRepository: foodLogRepository,
                            sessionNutritionAdvisor: sessionNutritionAdvisor,
                            foodDatabaseService: foodDatabaseService,
                            foodPhotoAnalysisService: foodPhotoAnalysisService
                        )
                    case .raceDay:
                        raceDayContent
                    }
                }
            }
            .navigationTitle("Nutrition")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.selectedTab == .raceDay {
                        Button {
                            viewModel.showingProductLibrary = true
                        } label: {
                            Image(systemName: "list.bullet")
                        }
                        .accessibilityIdentifier("nutrition.productLibraryButton")
                        .accessibilityLabel("Product library")
                        .accessibilityHint("Opens the product library")
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
            .sheet(isPresented: $viewModel.showingProductLibrary) {
                ProductLibraryView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingNutritionOnboarding) {
                if let race = viewModel.targetRace {
                    NutritionOnboardingSheet(
                        raceName: race.name,
                        raceDistanceKm: race.distanceKm,
                        raceGoalType: race.goalType,
                        initialPreferences: viewModel.preferences,
                        onGenerate: { updatedPreferences in
                            Task { await viewModel.generatePlan(with: updatedPreferences) }
                        },
                        onCancel: { }
                    )
                }
            }
            .sheet(
                isPresented: Binding(
                    get: { viewModel.feedbackTargetSessionId != nil },
                    set: { if !$0 { viewModel.closeFeedbackSheet() } }
                )
            ) {
                if let sessionId = viewModel.feedbackTargetSessionId,
                   let session = viewModel.gutTrainingSessions.first(where: { $0.id == sessionId }),
                   let plan = viewModel.plan {
                    NutritionFeedbackSheet(
                        sessionId: session.id,
                        sessionLabel: feedbackSessionLabel(session),
                        plannedCarbsPerHour: plan.carbsPerHour,
                        durationMinutes: Int(session.plannedDuration / 60),
                        availableProducts: viewModel.productsInPlan,
                        existingFeedback: viewModel.feedback(for: session.id),
                        onSave: { feedback in
                            Task { await viewModel.saveFeedback(feedback) }
                        }
                    )
                }
            }
        }
    }

    private func feedbackSessionLabel(_ session: TrainingSession) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d"
        return "Gut training · \(formatter.string(from: session.date))"
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        Picker("Nutrition Tab", selection: $viewModel.selectedTab) {
            ForEach(NutritionTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .accessibilityIdentifier("nutrition.tabPicker")
    }

    // MARK: - Race Day Content

    private var raceDayContent: some View {
        Group {
            if viewModel.isGenerating {
                NutritionGenerationLoadingView()
            } else if viewModel.isLoading {
                ProgressView("Loading nutrition plan...")
            } else if let plan = viewModel.plan {
                planContent(plan)
            } else {
                emptyState
            }
        }
    }

    private func planContent(_ plan: NutritionPlan) -> some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                if let race = viewModel.targetRace {
                    NutritionRaceHeroCard(
                        raceName: race.name,
                        raceDate: race.date,
                        distanceKm: race.distanceKm,
                        elevationGainM: race.elevationGainM,
                        estimatedDurationSeconds: viewModel.estimatedRaceDurationSeconds
                    )
                }

                NutritionTargetsCard(
                    carbsPerHour: plan.carbsPerHour,
                    hydrationMlPerHour: plan.hydrationMlPerHour,
                    sodiumMgPerHour: plan.sodiumMgPerHour,
                    totalCaffeineMg: plan.totalCaffeineMg,
                    totalCarbsGrams: viewModel.totalCarbsGrams,
                    estimatedDurationSeconds: viewModel.estimatedRaceDurationSeconds,
                    gutTrainingSessions: viewModel.gutTrainingSessionCount
                )

                HStack(spacing: Theme.Spacing.sm) {
                    Button {
                        viewModel.showingNutritionOnboarding = true
                    } label: {
                        Label("Edit preferences", systemImage: "slider.horizontal.3")
                            .font(.caption.weight(.medium))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityIdentifier("nutrition.editPreferencesButton")

                    Button {
                        Task { await viewModel.startPlanGeneration() }
                    } label: {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                            .font(.caption.weight(.medium))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityIdentifier("nutrition.regenerateButton")
                }

                NutritionTimelineView(entries: plan.entries)

                NutritionGutTrainingLogSection(
                    sessions: viewModel.gutTrainingSessions,
                    feedbacks: viewModel.feedbacks,
                    refinementNotes: viewModel.lastRefinementNotes,
                    onLogFeedback: { session in
                        viewModel.openFeedbackSheet(for: session.id)
                    }
                )
            }
            .padding()
        }
        .accessibilityIdentifier("nutrition.planContent")
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Nutrition Plan", systemImage: "fork.knife.circle")
        } description: {
            Text("Generate a race-day nutrition strategy based on your profile, race distance, and expected duration.")
        } actions: {
            Button {
                Task { await viewModel.startPlanGeneration() }
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
            .accessibilityIdentifier("nutrition.generateButton")
        }
        .accessibilityIdentifier("nutrition.emptyState")
    }
}
