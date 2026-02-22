import SwiftUI

struct WorkoutLibraryView: View {
    @State private var viewModel: WorkoutLibraryViewModel

    private let recipeRepository: any WorkoutRecipeRepository
    private let planRepository: any TrainingPlanRepository
    private let intervalWorkoutRepository: (any IntervalWorkoutRepository)?

    init(
        recipeRepository: any WorkoutRecipeRepository,
        planRepository: any TrainingPlanRepository,
        intervalWorkoutRepository: (any IntervalWorkoutRepository)? = nil
    ) {
        self.recipeRepository = recipeRepository
        self.planRepository = planRepository
        self.intervalWorkoutRepository = intervalWorkoutRepository
        _viewModel = State(initialValue: WorkoutLibraryViewModel(
            recipeRepository: recipeRepository,
            planRepository: planRepository,
            intervalWorkoutRepository: intervalWorkoutRepository
        ))
    }

    var body: some View {
        NavigationStack {
            List {
                categoryFilterSection
                intervalsSection
                templatesSection
            }
            .searchable(text: $viewModel.searchQuery)
            .navigationTitle("Workout Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingAddRecipe = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add workout")
                    .accessibilityHint("Opens form to create a custom workout recipe")
                }
            }
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .sheet(isPresented: $viewModel.showingAddRecipe) {
                EditRecipeSheet { recipe in
                    Task { await viewModel.saveRecipe(recipe) }
                }
            }
            .sheet(isPresented: $viewModel.showingIntervalBuilder) {
                if let repo = intervalWorkoutRepository {
                    IntervalBuilderView(
                        viewModel: IntervalBuilderViewModel(repository: repo)
                    )
                }
            }
            .sheet(item: $viewModel.templateToAdd) { template in
                AddToPlanDateSheet(template: template) { template, date in
                    Task { await viewModel.addToPlan(template: template, date: date) }
                }
            }
        }
    }

    // MARK: - Category Filter

    private var categoryFilterSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    categoryPill(title: "All", category: nil)
                    ForEach(WorkoutCategory.allCases, id: \.self) { category in
                        categoryPill(title: category.displayName, category: category)
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
        }
    }

    private func categoryPill(title: String, category: WorkoutCategory?) -> some View {
        let isSelected = viewModel.selectedCategory == category
        return Button {
            viewModel.selectedCategory = category
        } label: {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryBackground)
                .foregroundStyle(isSelected ? .white : Theme.Colors.label)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Filters workouts by \(title) category")
    }

    // MARK: - Intervals

    @ViewBuilder
    private var intervalsSection: some View {
        if !viewModel.filteredIntervalWorkouts.isEmpty {
            Section {
                ForEach(viewModel.filteredIntervalWorkouts) { workout in
                    NavigationLink {
                        IntervalWorkoutPreviewView(
                            viewModel: IntervalWorkoutPreviewViewModel(workout: workout)
                        )
                    } label: {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "timer")
                                .font(.title3)
                                .foregroundStyle(Theme.Colors.primary)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(workout.name)
                                    .font(.subheadline.weight(.semibold))
                                Text("\(workout.intervalCount) intervals")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        if workout.isUserCreated {
                            Button("Delete", role: .destructive) {
                                Task { await viewModel.deleteIntervalWorkout(id: workout.id) }
                            }
                        }
                    }
                }

                Button {
                    viewModel.showingIntervalBuilder = true
                } label: {
                    Label("Create Interval Workout", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Interval Workouts")
            }
        }
    }

    // MARK: - Templates

    private var templatesSection: some View {
        Section {
            ForEach(viewModel.filteredTemplates, id: \.id) { template in
                NavigationLink {
                    WorkoutTemplateDetailView(template: template) { selected in
                        viewModel.templateToAdd = selected
                    }
                } label: {
                    WorkoutTemplateRow(template: template)
                }
                .swipeActions(edge: .trailing) {
                    if template.isUserCreated {
                        Button("Delete", role: .destructive) {
                            Task { await viewModel.deleteRecipe(id: template.id) }
                        }
                    }
                }
            }
        }
    }
}
