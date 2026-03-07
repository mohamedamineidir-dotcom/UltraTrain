import SwiftUI

struct OnboardingView: View {
    @State private var viewModel: OnboardingViewModel
    var onComplete: () -> Void
    private let healthKitService: (any HealthKitServiceProtocol)?
    private let healthKitImportService: (any HealthKitImportServiceProtocol)?

    init(
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        healthKitService: (any HealthKitServiceProtocol)? = nil,
        healthKitImportService: (any HealthKitImportServiceProtocol)? = nil,
        initialFirstName: String? = nil,
        onComplete: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: OnboardingViewModel(
            athleteRepository: athleteRepository,
            raceRepository: raceRepository,
            initialFirstName: initialFirstName
        ))
        self.healthKitService = healthKitService
        self.healthKitImportService = healthKitImportService
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    OnboardingProgressBar(
                        current: viewModel.currentStep,
                        total: viewModel.totalSteps
                    )
                    .padding(.top, Theme.Spacing.sm)

                    stepContent
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                .safeAreaInset(edge: .bottom) {
                    bottomBar
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.currentStep > 0 {
                        Button {
                            viewModel.goBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.medium))
                        }
                        .accessibilityIdentifier("onboarding.backButton")
                    }
                }
            }
            .accessibilityAction(.escape) {
                if viewModel.currentStep > 0 {
                    viewModel.goBack()
                }
            }
        }
    }

    // MARK: - Steps 0-9

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case 0: ExperienceStepView(viewModel: viewModel)
        case 1: RunningHistoryStepView(viewModel: viewModel, healthKitService: healthKitService)
        case 2: PersonalBestsStepView(viewModel: viewModel)
        case 3: AboutYouStepView(viewModel: viewModel)
        case 4: BodyMetricsStepView(viewModel: viewModel)
        case 5: HeartRateStepView(viewModel: viewModel)
        case 6: RaceNameDateStepView(viewModel: viewModel)
        case 7: RaceProfileStepView(viewModel: viewModel)
        case 8: GoalTrainingStepView(viewModel: viewModel)
        case 9: OnboardingCompleteStepView(
            viewModel: viewModel,
            onComplete: onComplete,
            healthKitService: healthKitService,
            healthKitImportService: healthKitImportService
        )
        default: EmptyView()
        }
    }

    // MARK: - Bottom Bar

    @ViewBuilder
    private var bottomBar: some View {
        let isLastStep = viewModel.currentStep >= viewModel.totalSteps - 1

        if !isLastStep {
            VStack(spacing: 0) {
                Divider()
                PrimaryOnboardingButton(
                    title: viewModel.currentStep == 2 ? "Skip" : "Continue",
                    isEnabled: viewModel.canAdvance
                ) {
                    viewModel.advance()
                }
                .accessibilityIdentifier("onboarding.nextButton")
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
            }
            .background(Theme.Colors.background)
        }
    }
}
