import SwiftUI

struct PerformanceIndexStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                headerSection
                indexCard(
                    title: "ITRA Index",
                    input: $viewModel.itraIndexInput,
                    url: URL(string: "https://itra.run/Runners/RankingRunner")!,
                    linkLabel: "Find my ITRA index"
                )
                indexCard(
                    title: "UTMB Index",
                    input: $viewModel.utmbIndexInput,
                    url: URL(string: "https://utmb.world/utmb-index")!,
                    linkLabel: "Find my UTMB index"
                )
                skipNote
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Circle().fill(Theme.Gradients.warmCoralCTA))
                .shadow(color: Theme.Colors.warmCoral.opacity(0.3), radius: 8, y: 4)

            Text("Your Racing Index")
                .font(.title2.bold())
            Text("If you have an ITRA or UTMB index, add it here — it sharpens your finish-time predictions with independent racing history.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(.bottom, Theme.Spacing.xs)
    }

    // MARK: - Index Card

    private func indexCard(
        title: String,
        input: Binding<String>,
        url: URL,
        linkLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(LocalizedStringKey(title))
                .font(.headline)
                .foregroundStyle(Theme.Colors.label)

            HStack {
                TextField("e.g. 550", text: input)
                    .keyboardType(.numberPad)
                    .font(.body.monospacedDigit())
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 120)
                Spacer()
            }

            Link(destination: url) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right.square")
                    Text(LocalizedStringKey(linkLabel))
                }
                .font(.caption)
                .foregroundStyle(Theme.Colors.warmCoral)
            }
        }
        .onboardingCardStyle()
    }

    // MARK: - Skip Note

    private var skipNote: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Theme.Colors.info)
            Text("Optional — most runners don't have one yet. Skip and add it later from Settings, or after your race.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(Theme.Spacing.md)
        .onboardingCardStyle()
    }
}
