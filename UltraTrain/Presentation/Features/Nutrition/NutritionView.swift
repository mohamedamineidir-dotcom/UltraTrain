import SwiftUI

struct NutritionView: View {
    @State private var viewModel: NutritionViewModel

    private let athleteRepository: any AthleteRepository
    private let planRepository: any TrainingPlanRepository
    private let nutritionRepository: any NutritionRepository
    private let foodLogRepository: any FoodLogRepository
    private let sessionNutritionAdvisor: any SessionNutritionAdvisor
    private let foodDatabaseService: (any FoodDatabaseServiceProtocol)?

    init(
        nutritionRepository: any NutritionRepository,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        planRepository: any TrainingPlanRepository,
        nutritionGenerator: any GenerateNutritionPlanUseCase,
        foodLogRepository: any FoodLogRepository,
        sessionNutritionAdvisor: any SessionNutritionAdvisor,
        foodDatabaseService: (any FoodDatabaseServiceProtocol)? = nil
    ) {
        self.athleteRepository = athleteRepository
        self.planRepository = planRepository
        self.nutritionRepository = nutritionRepository
        self.foodLogRepository = foodLogRepository
        self.sessionNutritionAdvisor = sessionNutritionAdvisor
        self.foodDatabaseService = foodDatabaseService

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
                            foodDatabaseService: foodDatabaseService
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
        }
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
            if viewModel.isLoading {
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
            LazyVStack(spacing: Theme.Spacing.sm) {
                NutritionSummaryCard(
                    caloriesPerHour: plan.caloriesPerHour,
                    hydrationMlPerHour: plan.hydrationMlPerHour,
                    sodiumMgPerHour: plan.sodiumMgPerHour,
                    totalCalories: viewModel.totalCaloriesInPlan,
                    gutTrainingSessions: viewModel.gutTrainingSessionCount
                )

                NutritionScheduleView(entries: plan.entries)
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
            .accessibilityIdentifier("nutrition.generateButton")
        }
        .accessibilityIdentifier("nutrition.emptyState")
    }
}
