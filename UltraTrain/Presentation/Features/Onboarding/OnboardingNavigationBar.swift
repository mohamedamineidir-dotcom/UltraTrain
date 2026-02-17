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
                        Text("Back")
                    }
                }
                .foregroundStyle(Theme.Colors.secondaryLabel)
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
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canAdvance)
                .accessibilityIdentifier("onboarding.nextButton")
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }
}
