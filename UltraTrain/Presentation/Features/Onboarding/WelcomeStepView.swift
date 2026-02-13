import SwiftUI

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Theme.Colors.primary)

            Text("Welcome to UltraTrain")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Your ultra trail training companion")
                .font(.title3)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            Text("We'll set up your profile and first race goal in a few quick steps.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            Spacer()
        }
        .padding()
    }
}
