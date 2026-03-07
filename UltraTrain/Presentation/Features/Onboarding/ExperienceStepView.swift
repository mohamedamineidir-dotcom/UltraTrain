import SwiftUI

struct ExperienceStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xxl) {
                // Header
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.accentColor)

                    Text("Experience Level")
                        .font(.title.bold())

                    Text("This helps us build a plan that matches your fitness.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.xl)

                VStack(spacing: Theme.Spacing.lg) {
                    // Experience cards
                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(ExperienceLevel.allCases, id: \.self) { level in
                            ExperienceLevelCard(
                                level: level,
                                isSelected: viewModel.experienceLevel == level,
                                onTap: { viewModel.experienceLevel = level }
                            )
                        }
                    }

                    // Unit preference
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Preferred Units")
                            .font(.headline)
                        Picker("Units", selection: $viewModel.preferredUnit) {
                            Text("Metric (km, kg)").tag(UnitPreference.metric)
                            Text("Imperial (mi, lbs)").tag(UnitPreference.imperial)
                        }
                        .pickerStyle(.segmented)
                    }
                    .cardStyle()
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
        }
    }
}
