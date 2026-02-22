import SwiftUI

struct TrainingNutritionView: View {
    @State private var viewModel: TrainingNutritionViewModel

    init(
        athleteRepository: any AthleteRepository,
        planRepository: any TrainingPlanRepository,
        nutritionRepository: any NutritionRepository,
        foodLogRepository: any FoodLogRepository,
        sessionNutritionAdvisor: any SessionNutritionAdvisor
    ) {
        _viewModel = State(initialValue: TrainingNutritionViewModel(
            athleteRepository: athleteRepository,
            planRepository: planRepository,
            nutritionRepository: nutritionRepository,
            foodLogRepository: foodLogRepository,
            sessionNutritionAdvisor: sessionNutritionAdvisor
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading nutrition data...")
            } else if let target = viewModel.dailyTarget {
                dashboardContent(target)
            } else {
                noAthleteState
            }
        }
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $viewModel.showingAddEntry) {
            AddFoodEntrySheet { entry in
                Task { await viewModel.addEntry(entry) }
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .accessibilityIdentifier("nutrition.trainingView")
    }

    // MARK: - Dashboard Content

    private func dashboardContent(_ target: DailyNutritionTarget) -> some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.sm) {
                phaseBadge(target.trainingPhase)

                sessionTypeBadge(target.sessionType)

                MacroRingChart(
                    caloriesConsumed: viewModel.consumedCalories,
                    caloriesTarget: target.caloriesTarget,
                    carbsConsumed: viewModel.consumedCarbs,
                    carbsTarget: target.carbsGramsTarget,
                    proteinConsumed: viewModel.consumedProtein,
                    proteinTarget: target.proteinGramsTarget,
                    fatConsumed: viewModel.consumedFat,
                    fatTarget: target.fatGramsTarget
                )
                .cardStyle()

                hydrationCard(target)

                if let advice = target.sessionAdvice {
                    SessionNutritionSection(advice: advice)
                }

                FoodLogSection(
                    entries: viewModel.todayEntries,
                    onDelete: { id in
                        Task { await viewModel.deleteEntry(id: id) }
                    },
                    onAddTapped: {
                        viewModel.showingAddEntry = true
                    }
                )

                WeeklyNutritionChart(
                    entries: viewModel.weeklyEntries,
                    dailyTarget: target.caloriesTarget
                )
            }
            .padding()
        }
    }

    // MARK: - Phase Badge

    private func phaseBadge(_ phase: TrainingPhase) -> some View {
        HStack {
            Image(systemName: "flag.fill")
                .font(.caption)
                .accessibilityHidden(true)
            Text(phase.rawValue.capitalized)
                .font(.caption.bold())
            Text("Phase")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .foregroundStyle(phaseColor(phase))
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        .background(phaseColor(phase).opacity(0.12))
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current training phase: \(phase.rawValue)")
    }

    private func phaseColor(_ phase: TrainingPhase) -> Color {
        switch phase {
        case .base: return .blue
        case .build: return .orange
        case .peak: return .red
        case .taper: return .green
        case .race: return .purple
        case .recovery: return .mint
        }
    }

    // MARK: - Session Type Badge

    @ViewBuilder
    private func sessionTypeBadge(_ sessionType: SessionType?) -> some View {
        if let sessionType {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "figure.run")
                    .font(.caption)
                    .accessibilityHidden(true)
                Text("Today: \(sessionType.displayLabel)")
                    .font(.caption.bold())
            }
            .foregroundStyle(Theme.Colors.primary)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Today's session: \(sessionType.displayLabel)")
        } else {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "bed.double.fill")
                    .font(.caption)
                    .accessibilityHidden(true)
                Text("Rest Day")
                    .font(.caption.bold())
            }
            .foregroundStyle(Theme.Colors.secondaryLabel)
            .accessibilityLabel("Today is a rest day")
        }
    }

    // MARK: - Hydration Card

    private func hydrationCard(_ target: DailyNutritionTarget) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Label("Hydration", systemImage: "drop.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.cyan)
                Spacer()
                Text("\(viewModel.consumedHydration) / \(target.hydrationMlTarget) ml")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            let progress = target.hydrationMlTarget > 0
                ? min(Double(viewModel.consumedHydration) / Double(target.hydrationMlTarget), 1.0)
                : 0.0

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.cyan.opacity(0.15))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.cyan)
                        .frame(width: geometry.size.width * progress, height: 10)
                        .animation(.easeInOut(duration: 0.4), value: progress)
                }
            }
            .frame(height: 10)
        }
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Hydration: \(viewModel.consumedHydration) of \(target.hydrationMlTarget) milliliters"
        )
        .accessibilityValue("\(Int(target.hydrationMlTarget > 0 ? (Double(viewModel.consumedHydration) / Double(target.hydrationMlTarget) * 100) : 0)) percent")
        .accessibilityIdentifier("nutrition.hydrationCard")
    }

    // MARK: - No Athlete State

    private var noAthleteState: some View {
        ContentUnavailableView {
            Label("No Profile", systemImage: "person.crop.circle.badge.exclamationmark")
        } description: {
            Text("Complete your athlete profile to see personalized nutrition targets.")
        }
        .accessibilityIdentifier("nutrition.noAthleteState")
    }
}

// MARK: - SessionType Display Extension

private extension SessionType {
    var displayLabel: String {
        switch self {
        case .longRun: return "Long Run"
        case .tempo: return "Tempo"
        case .intervals: return "Intervals"
        case .verticalGain: return "Vertical Gain"
        case .backToBack: return "Back-to-Back"
        case .recovery: return "Recovery Run"
        case .crossTraining: return "Cross Training"
        case .rest: return "Rest"
        }
    }
}
