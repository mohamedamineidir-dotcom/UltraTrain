import SwiftUI

struct RaceNameDateStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xxl) {
                // Header
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(Circle().fill(Theme.Gradients.warmCoralCTA))
                        .shadow(color: Theme.Colors.warmCoral.opacity(0.3), radius: 8, y: 4)

                    Text("Your A-Race")
                        .font(.title.bold())

                    Text("What race are you training for?")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.xl)

                VStack(spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Race Name")
                            .font(.headline)
                        RaceAutoCompleteField(text: $viewModel.raceName) { race in
                            viewModel.raceDistanceKm = race.distanceKm
                            viewModel.raceElevationGainM = race.elevationGainM
                            viewModel.raceElevationLossM = race.elevationLossM
                            if let date = race.nextEditionDate, date > Date.now {
                                viewModel.raceDate = date
                            }
                        }
                    }
                    .onboardingCardStyle()

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Race Date")
                            .font(.headline)
                        DatePicker(
                            "Race Date",
                            selection: $viewModel.raceDate,
                            in: Date.now...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                    }
                    .onboardingCardStyle()
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
        }
    }
}
