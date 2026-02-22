import SwiftUI

struct ExperienceStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerSection
                experienceCards
                unitSection
            }
            .padding()
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("What's your experience level?")
                .font(.title2.bold())
            Text("This helps us build a plan that matches your fitness.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
    }

    private var experienceCards: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(ExperienceLevel.allCases, id: \.self) { level in
                ExperienceLevelCard(
                    level: level,
                    isSelected: viewModel.experienceLevel == level,
                    onTap: { viewModel.experienceLevel = level }
                )
            }
        }
    }

    private var unitSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Preferred Units")
                .font(.headline)
            Picker("Units", selection: $viewModel.preferredUnit) {
                Text("Metric (km, kg)").tag(UnitPreference.metric)
                Text("Imperial (mi, lbs)").tag(UnitPreference.imperial)
            }
            .pickerStyle(.segmented)
            .accessibilityHint("Choose between metric and imperial measurement units")
        }
        .cardStyle()
    }
}
