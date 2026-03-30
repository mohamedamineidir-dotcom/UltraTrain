import SwiftUI

struct InjuryStrengthStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xxl) {
                header
                cards
            }
        }
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 32))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.7, blue: 0.5), Color(red: 0.1, green: 0.5, blue: 0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .shadow(color: Color(red: 0.2, green: 0.7, blue: 0.5).opacity(0.3), radius: 8, y: 4)

            Text("Injury & Strength")
                .font(.title.bold())

            Text("Help us keep you healthy and strong.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Theme.Spacing.xl)
    }

    private var cards: some View {
        VStack(spacing: Theme.Spacing.lg) {
            painFrequencyCard
            injuryCountCard
            recentInjuryCard
            strengthPreferenceCard
            if viewModel.strengthTrainingPreference == .yes {
                strengthLocationCard
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .animation(.easeInOut(duration: 0.2), value: viewModel.strengthTrainingPreference)
    }

    private var painFrequencyCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Running-Related Pain")
                .font(.headline)
            Text("How often do you experience pain during or after running?")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            ForEach(PainFrequency.allCases, id: \.self) { frequency in
                selectionButton(
                    title: frequency.displayName,
                    isSelected: viewModel.painFrequency == frequency
                ) {
                    viewModel.painFrequency = frequency
                }
            }
        }
        .onboardingCardStyle()
    }

    private var injuryCountCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Injuries (Last 6 Months)")
                .font(.headline)
            Text("How many injuries kept you from running?")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            ForEach(InjuryCount.allCases, id: \.self) { count in
                selectionButton(
                    title: count.displayName,
                    isSelected: viewModel.injuryCountLastYear == count
                ) {
                    viewModel.injuryCountLastYear = count
                }
            }
        }
        .onboardingCardStyle()
    }

    private var recentInjuryCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Toggle(isOn: $viewModel.hasRecentInjury) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Currently Injured")
                        .font(.headline)
                    Text("Are you dealing with an injury right now?")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
            .tint(Theme.Colors.warmCoral)
        }
        .onboardingCardStyle()
    }

    private var strengthPreferenceCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Strength Training")
                .font(.headline)
            Text("Include strength & conditioning sessions in your plan?")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            ForEach(StrengthTrainingPreference.allCases, id: \.self) { pref in
                selectionButton(
                    title: pref.displayName,
                    isSelected: viewModel.strengthTrainingPreference == pref
                ) {
                    viewModel.strengthTrainingPreference = pref
                }
            }
        }
        .onboardingCardStyle()
    }

    private var strengthLocationCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Where Will You Train?")
                .font(.headline)
            ForEach(StrengthTrainingLocation.allCases, id: \.self) { location in
                selectionButton(
                    title: location.displayName,
                    isSelected: viewModel.strengthTrainingLocation == location
                ) {
                    viewModel.strengthTrainingLocation = location
                }
            }
        }
        .onboardingCardStyle()
    }

    private func selectionButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding(Theme.Spacing.md)
            .background(isSelected ? AnyShapeStyle(Theme.Colors.warmCoral) : AnyShapeStyle(Theme.Colors.secondaryBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
        }
        .buttonStyle(.plain)
    }
}
