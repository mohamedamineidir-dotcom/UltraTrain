import SwiftUI

struct AboutYouStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xxl) {
                // Header
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(Circle().fill(Theme.Gradients.warmCoralCTA))
                        .shadow(color: Theme.Colors.warmCoral.opacity(0.3), radius: 8, y: 4)

                    Text("About You")
                        .font(.title.bold())

                    Text("We'll use this to personalize your experience.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.xl)

                // Fields
                VStack(spacing: Theme.Spacing.md) {
                    OnboardingTextField(
                        placeholder: "First Name",
                        text: $viewModel.firstName,
                        textContentType: .givenName,
                        autocapitalization: .words
                    )
                    .accessibilityIdentifier("onboarding.firstNameField")

                    OnboardingTextField(
                        placeholder: "Last Name",
                        text: $viewModel.lastName,
                        textContentType: .familyName,
                        autocapitalization: .words
                    )
                    .accessibilityIdentifier("onboarding.lastNameField")

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Date of Birth")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                        DatePicker(
                            "Date of Birth",
                            selection: $viewModel.dateOfBirth,
                            in: ...Date.now,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
        }
    }
}
