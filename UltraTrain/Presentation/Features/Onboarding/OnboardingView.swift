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
        onComplete: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: OnboardingViewModel(
            athleteRepository: athleteRepository,
            raceRepository: raceRepository
        ))
        self.healthKitService = healthKitService
        self.healthKitImportService = healthKitImportService
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                OnboardingProgressBar(
                    current: viewModel.currentStep,
                    total: viewModel.totalSteps
                )

                Spacer(minLength: 0)

                Group {
                    switch viewModel.currentStep {
                    case 0: WelcomeStepView()
                    case 1: ExperienceStepView(viewModel: viewModel)
                    case 2: RunningHistoryStepView(viewModel: viewModel, healthKitService: healthKitService)
                    case 3: PhysicalDataStepView(viewModel: viewModel)
                    case 4: RaceGoalStepView(viewModel: viewModel)
                    case 5: OnboardingCompleteStepView(
                        viewModel: viewModel,
                        onComplete: onComplete,
                        healthKitService: healthKitService,
                        healthKitImportService: healthKitImportService
                    )
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer(minLength: 0)

                OnboardingNavigationBar(viewModel: viewModel)
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityAction(.escape) {
                if viewModel.currentStep > 0 {
                    viewModel.goBack()
                }
            }
        }
    }
}
