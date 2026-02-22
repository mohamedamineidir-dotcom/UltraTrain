import SwiftUI

struct PostRaceWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PostRaceWizardViewModel

    init(
        race: Race,
        raceRepository: any RaceRepository,
        raceReflectionRepository: any RaceReflectionRepository,
        runRepository: any RunRepository,
        finishEstimateRepository: any FinishEstimateRepository
    ) {
        _viewModel = State(
            initialValue: PostRaceWizardViewModel(
                race: race,
                raceRepository: raceRepository,
                raceReflectionRepository: raceReflectionRepository,
                runRepository: runRepository,
                finishEstimateRepository: finishEstimateRepository
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                stepContent
            }
            .navigationTitle("Post-Race Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarLeading
                toolbarTrailing
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .task { await viewModel.load() }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved { dismiss() }
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: Theme.Spacing.xs) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.Colors.secondaryBackground)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.Colors.primary)
                        .frame(width: geo.size.width * viewModel.stepProgress, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.stepProgress)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, Theme.Spacing.md)

            Text(stepTitle)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.vertical, Theme.Spacing.sm)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(viewModel.currentStep.rawValue + 1) of \(PostRaceWizardViewModel.Step.allCases.count): \(stepTitle)")
    }

    private var stepTitle: String {
        switch viewModel.currentStep {
        case .result: "Race Result"
        case .pacing: "Pacing"
        case .nutrition: "Nutrition"
        case .weather: "Weather"
        case .takeaways: "Takeaways"
        case .summary: "Summary"
        }
    }

    // MARK: - Step Content

    private var stepContent: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                switch viewModel.currentStep {
                case .result:
                    PostRaceResultStep(viewModel: viewModel)
                case .pacing:
                    PostRacePacingStep(viewModel: viewModel)
                case .nutrition:
                    PostRaceNutritionStep(viewModel: viewModel)
                case .weather:
                    PostRaceWeatherStep(viewModel: viewModel)
                case .takeaways:
                    PostRaceTakeawaysStep(viewModel: viewModel)
                case .summary:
                    PostRaceSummaryStep(viewModel: viewModel)
                }
            }
            .padding(Theme.Spacing.md)
        }
    }

    // MARK: - Toolbar

    private var toolbarLeading: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if viewModel.isFirstStep {
                Button("Cancel") { dismiss() }
                    .accessibilityHint("Discards changes and closes the wizard")
            } else {
                Button("Back") { viewModel.previousStep() }
                    .accessibilityHint("Go to the previous step")
            }
        }
    }

    private var toolbarTrailing: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if viewModel.isLastStep {
                Button("Save") {
                    Task { await viewModel.save() }
                }
                .bold()
                .disabled(viewModel.isSaving)
                .accessibilityHint("Saves the post-race reflection")
            } else {
                Button("Next") { viewModel.nextStep() }
                    .bold()
                    .disabled(!viewModel.canProceed)
                    .accessibilityHint("Go to the next step")
            }
        }
    }
}
