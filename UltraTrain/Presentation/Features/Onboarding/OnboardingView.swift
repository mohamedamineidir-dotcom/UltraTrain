import SwiftUI
import StoreKit

struct OnboardingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.requestReview) private var requestReview
    @State private var viewModel: OnboardingViewModel
    /// RR-43: fired once, the first time the athlete reaches "About You" —
    /// notification permission used to be requested at app launch/sign-in,
    /// which could land before onboarding even started. Asking mid-flow,
    /// once the athlete has invested a few steps, reads as less abrupt.
    @State private var hasRequestedNotificationPermission = false
    /// RR-43: fired once, the moment the athlete advances past "Goal and
    /// Training" (step 9) — far enough from both the notification prompt
    /// (step 3) and account creation/paywall (step 12-13) that neither
    /// competes with it for the athlete's goodwill.
    @State private var hasRequestedReview = false
    var onComplete: () -> Void
    private let healthKitService: (any HealthKitServiceProtocol)?
    private let healthKitImportService: (any HealthKitImportServiceProtocol)?
    /// RR-41: account creation moved from before onboarding to step 12
    /// (right before "You're All Set"), so it needs the auth dependencies
    /// that used to live only on HeroLandingView/SignUpView.
    private let authService: any AuthServiceProtocol
    private let referralRepository: any ReferralRepository
    private let clearAllDataUseCase: any ClearAllDataUseCase
    /// Fires only in the rare case where the embedded sign-up step
    /// discovers (e.g. via Apple/Google) that this is actually an existing
    /// account. We abandon the in-progress onboarding answers and route
    /// through the normal existing-user path instead, same as "I already
    /// have an account" would have.
    var onExistingAccountSignedIn: (String?, String?) -> Void
    /// RR-43: requests notification permission (APNs registration included)
    /// once the athlete reaches "About You".
    var onReachedAboutYouStep: () -> Void

    init(
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        healthKitService: (any HealthKitServiceProtocol)? = nil,
        healthKitImportService: (any HealthKitImportServiceProtocol)? = nil,
        authService: any AuthServiceProtocol,
        referralRepository: any ReferralRepository,
        clearAllDataUseCase: any ClearAllDataUseCase,
        initialFirstName: String? = nil,
        initialLastName: String? = nil,
        onExistingAccountSignedIn: @escaping (String?, String?) -> Void = { _, _ in },
        onReachedAboutYouStep: @escaping () -> Void = {},
        onComplete: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: OnboardingViewModel(
            athleteRepository: athleteRepository,
            raceRepository: raceRepository,
            initialFirstName: initialFirstName,
            initialLastName: initialLastName
        ))
        self.healthKitService = healthKitService
        self.healthKitImportService = healthKitImportService
        self.authService = authService
        self.referralRepository = referralRepository
        self.clearAllDataUseCase = clearAllDataUseCase
        self.onExistingAccountSignedIn = onExistingAccountSignedIn
        self.onReachedAboutYouStep = onReachedAboutYouStep
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if colorScheme == .dark {
                        Theme.Gradients.premiumBackground
                    } else {
                        LinearGradient(
                            colors: [
                                Color(red: 0.97, green: 0.96, blue: 0.94),
                                Color(red: 1.0, green: 0.97, blue: 0.95)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                .ignoresSafeArea()

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
            .onChange(of: viewModel.currentStep) { oldValue, newValue in
                // RR-43: About You is step 3, regardless of race/no-race
                // branching earlier in the flow.
                if newValue == 3 && !hasRequestedNotificationPermission {
                    hasRequestedNotificationPermission = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onReachedAboutYouStep()
                    }
                }
                // Fires the moment the athlete leaves step 9 (Goal and
                // Training) in either direction the flow can exit it
                // (straight to Uphill Details, or skipped ahead to Account
                // Creation for a no-race plan).
                //
                // Apple explicitly warns against calling requestReview()
                // synchronously in direct response to a UI event: on a real
                // device (this can't be verified in Simulator, which never
                // submits real ratings regardless of timing) the system can
                // silently decline to show the prompt at all if it's asked
                // for while a transition/animation is still in flight. The
                // step change above kicks off a 0.3s animated transition,
                // so wait for it to settle before asking.
                if oldValue == 9 && newValue != 9 && !hasRequestedReview {
                    hasRequestedReview = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        requestReview()
                    }
                }
            }
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

    // MARK: - Steps 0-13

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case 0: ExperienceStepView(viewModel: viewModel)
        case 1: RunningHistoryStepView(viewModel: viewModel, healthKitService: healthKitService)
        case 2: PersonalBestsStepView(viewModel: viewModel)
        case 3: AboutYouStepView(viewModel: viewModel)
        case 4: BodyMetricsStepView(viewModel: viewModel)
        case 5: HeartRateStepView(viewModel: viewModel)
        case 6: InjuryStrengthStepView(viewModel: viewModel)
        case 7: RaceNameDateStepView(viewModel: viewModel)
        case 8: RaceProfileStepView(viewModel: viewModel)
        case 9: GoalTrainingStepView(viewModel: viewModel)
        case 10: UphillDetailsStepView(viewModel: viewModel)
        case 11: VolumePreviewStepView(viewModel: viewModel)
        case 12: accountCreationStep
        case 13: OnboardingCompleteStepView(
            viewModel: viewModel,
            onComplete: onComplete,
            healthKitService: healthKitService,
            healthKitImportService: healthKitImportService
        )
        default: EmptyView()
        }
    }

    /// RR-41: if we're resuming an onboarding session that was killed
    /// after account creation but before "You're All Set" (rare: app
    /// backgrounded/crashed mid-flow), the athlete is already
    /// authenticated — skip straight past this step instead of asking
    /// them to sign up again.
    @ViewBuilder
    private var accountCreationStep: some View {
        if authService.isAuthenticated() {
            Color.clear.onAppear { viewModel.advance() }
        } else {
            SignUpView(
                authService: authService,
                referralRepository: referralRepository,
                onAuthenticated: { isNewUser, firstName, lastName in
                    if isNewUser {
                        Task { try? await clearAllDataUseCase.execute() }
                        viewModel.advance()
                    } else {
                        onExistingAccountSignedIn(firstName, lastName)
                    }
                }
            )
        }
    }

    private var pbStepButtonTitle: String {
        if viewModel.currentStep == 2 {
            let hasIndex = !viewModel.itraIndexInput.isEmpty || !viewModel.utmbIndexInput.isEmpty
            return (viewModel.hasAnyPB || hasIndex) ? "Continue" : "Skip"
        }
        return "Continue"
    }

    // MARK: - Bottom Bar

    @ViewBuilder
    private var bottomBar: some View {
        let isLastStep = viewModel.currentStep >= viewModel.totalSteps - 1
        // Step 12 (account creation) has its own submit/social-auth buttons.
        let hidesGenericBar = isLastStep || viewModel.currentStep == 12

        if !hidesGenericBar {
            VStack(spacing: 0) {
                Divider()
                PrimaryOnboardingButton(
                    title: pbStepButtonTitle,
                    isEnabled: viewModel.canAdvance
                ) {
                    viewModel.advance()
                }
                .accessibilityIdentifier("onboarding.nextButton")
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
            }
            .background(
                colorScheme == .dark
                    ? Color(red: 0.039, green: 0.086, blue: 0.157)
                    : Color(red: 1.0, green: 0.97, blue: 0.95)
            )
        }
    }
}
