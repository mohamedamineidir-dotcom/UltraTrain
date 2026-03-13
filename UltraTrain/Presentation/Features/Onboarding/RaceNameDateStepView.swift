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
                    // Race Name — always visible
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Race Name")
                            .font(.headline)
                        RaceAutoCompleteField(text: $viewModel.raceName) { race in
                            viewModel.raceDistanceKm = race.distanceKm
                            viewModel.raceElevationGainM = race.elevationGainM
                            viewModel.raceElevationLossM = race.elevationLossM
                            viewModel.raceTerrainDifficulty = race.terrainDifficulty
                            viewModel.isKnownRace = true
                            if let date = race.nextEditionDate, date > Date.now {
                                viewModel.raceDate = date
                            }
                        }
                    }
                    .onboardingCardStyle()
                    .opacity(viewModel.hasNoRace ? 0.4 : 1.0)
                    .disabled(viewModel.hasNoRace)
                    .onChange(of: viewModel.raceName) {
                        if viewModel.isKnownRace {
                            let matches = RaceDatabase.search(query: viewModel.raceName)
                            if !matches.contains(where: { $0.name == viewModel.raceName }) {
                                viewModel.isKnownRace = false
                            }
                        }
                    }

                    if viewModel.isShortRoadRace && !viewModel.hasNoRace {
                        shortRoadRaceWarning
                    }

                    // Race Date — always visible
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
                    .opacity(viewModel.hasNoRace ? 0.4 : 1.0)
                    .disabled(viewModel.hasNoRace)

                    // No race option — at the bottom
                    Button {
                        viewModel.hasNoRace.toggle()
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            Image(systemName: viewModel.hasNoRace ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(viewModel.hasNoRace ? Theme.Colors.warmCoral : Theme.Colors.secondaryLabel)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("I don't have a race")
                                    .font(.subheadline.bold())
                                Text("Just build my fitness")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.secondaryLabel)
                            }
                            Spacer()
                        }
                        .padding(Theme.Spacing.md)
                        .background(
                            viewModel.hasNoRace
                                ? AnyShapeStyle(Theme.Colors.warmCoral.opacity(0.12))
                                : AnyShapeStyle(Theme.Colors.secondaryBackground)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                    }
                    .buttonStyle(.plain)
                    .onboardingCardStyle()

                    if viewModel.hasNoRace {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Image(systemName: "figure.run")
                                .font(.title)
                                .foregroundStyle(Theme.Colors.warmCoral)
                            Text("No problem! We'll build a general fitness plan to keep you progressing. You can add a target race anytime later.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.Colors.secondaryLabel)
                        }
                        .onboardingCardStyle()
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .animation(.easeInOut(duration: 0.2), value: viewModel.hasNoRace)
            }
        }
    }

    private var shortRoadRaceWarning: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.blue)
            Text("UltraTrain is built for trail and ultra-distance races. For shorter road events, features like altitude training and nutrition planning shine most on longer distances. You can still create a plan — but to get the most out of this app, consider using it for your next trail or long-distance adventure!")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(Theme.Spacing.md)
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
    }
}
