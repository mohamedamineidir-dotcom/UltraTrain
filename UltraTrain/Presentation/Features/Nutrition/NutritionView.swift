import SwiftUI

struct NutritionView: View {
    @State private var viewModel: NutritionViewModel

    init(
        nutritionRepository: any NutritionRepository,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        planRepository: any TrainingPlanRepository,
        nutritionGenerator: any GenerateNutritionPlanUseCase
    ) {
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
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading nutrition plan...")
                } else if let plan = viewModel.plan {
                    planContent(plan)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Nutrition")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingProductLibrary = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                    .accessibilityLabel("Product library")
                    .accessibilityHint("Opens the product library")
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
        }
    }
}
