import SwiftUI

struct UphillDetailsStepView: View {
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
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [Color(red: 0.35, green: 0.55, blue: 0.3), Color(red: 0.2, green: 0.4, blue: 0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .shadow(color: Color(red: 0.35, green: 0.55, blue: 0.3).opacity(0.3), radius: 8, y: 4)

            Text("Your Uphill Terrain")
                .font(.title.bold())

            Text("This helps us adapt your vertical sessions.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Theme.Spacing.xl)
    }

    private var cards: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Uphill duration (not shown for treadmill-only)
            if viewModel.verticalGainEnvironment != .treadmill {
                uphillDurationCard
            }

            // Treadmill incline (shown for treadmill or mixed)
            if viewModel.verticalGainEnvironment == .treadmill || viewModel.verticalGainEnvironment == .mixed {
                treadmillInclineCard
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private var uphillDurationCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Nearest Uphill")
                .font(.headline)
            Text("How long is the longest uphill near you?")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            ForEach(UphillDuration.allCases, id: \.self) { duration in
                selectionButton(
                    title: duration.displayName,
                    isSelected: viewModel.uphillDuration == duration
                ) {
                    viewModel.uphillDuration = duration
                }
            }
            Text("This helps us adapt your vertical gain sessions to your terrain.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .onboardingCardStyle()
    }

    private var treadmillInclineCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Treadmill Incline")
                .font(.headline)
            Text("What is the maximum incline on your treadmill?")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            ForEach(TreadmillIncline.allCases, id: \.self) { incline in
                selectionButton(
                    title: incline.displayName,
                    isSelected: viewModel.treadmillMaxIncline == incline
                ) {
                    viewModel.treadmillMaxIncline = incline
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
