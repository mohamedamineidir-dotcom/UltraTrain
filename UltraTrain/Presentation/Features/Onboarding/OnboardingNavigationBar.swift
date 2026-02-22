import SwiftUI

struct OnboardingNavigationBar: View {
    let viewModel: OnboardingViewModel

    private var isLastStep: Bool {
        viewModel.currentStep >= viewModel.totalSteps - 1
    }

    var body: some View {
        HStack {
            if viewModel.currentStep > 0 {
                Button {
                    viewModel.goBack()
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "chevron.left")
                            .accessibilityHidden(true)
                        Text("Back")
                    }
                }
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityHint("Go to the previous step")
                .accessibilityIdentifier("onboarding.backButton")
            }

            Spacer()

            if !isLastStep {
                Button {
                    viewModel.advance()
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                            .accessibilityHidden(true)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canAdvance)
                .accessibilityHint("Continue to the next step")
                .accessibilityIdentifier("onboarding.nextButton")
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }
}
