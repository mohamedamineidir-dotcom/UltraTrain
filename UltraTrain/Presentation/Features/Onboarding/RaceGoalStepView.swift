import SwiftUI

struct RaceGoalStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerSection
                raceInfoSection
                elevationSection
                goalTypeSection
                terrainSection
            }
            .padding()
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Your A-Race Goal")
                .font(.title2.bold())
            Text("Set up your principal objective race. Everything else will be built around it.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
    }

    private var raceInfoSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Race Info")
                .font(.headline)
            TextField("Race Name (e.g. UTMB, Diagonale des Fous)", text: $viewModel.raceName)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .accessibilityIdentifier("onboarding.raceNameField")
            DatePicker(
                "Race Date",
                selection: $viewModel.raceDate,
                in: Date.now...,
                displayedComponents: .date
            )
            LabeledStepper(
                label: "Distance",
                value: $viewModel.raceDistanceKm,
                range: 1...500,
                step: 5,
                unit: "km"
            )
        }
        .cardStyle()
    }

    private var elevationSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Elevation")
                .font(.headline)
            LabeledStepper(
                label: "D+ (gain)",
                value: $viewModel.raceElevationGainM,
                range: 0...20000,
                step: 100,
                unit: "m"
            )
            Divider()
            LabeledStepper(
                label: "D- (loss)",
                value: $viewModel.raceElevationLossM,
                range: 0...20000,
                step: 100,
                unit: "m"
            )
        }
        .cardStyle()
    }

    private var goalTypeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Goal")
                .font(.headline)
            Picker("Goal Type", selection: $viewModel.raceGoalType) {
                ForEach(RaceGoalSelection.allCases, id: \.self) { goal in
                    Text(goal.displayName).tag(goal)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.raceGoalType == .targetTime {
                targetTimeFields
            }
            if viewModel.raceGoalType == .targetRanking {
                LabeledIntStepper(
                    label: "Target Position",
                    value: $viewModel.raceTargetRanking,
                    range: 1...5000,
                    unit: ""
                )
            }
        }
        .cardStyle()
        .animation(.easeInOut(duration: 0.2), value: viewModel.raceGoalType)
    }

    private var targetTimeFields: some View {
        HStack(spacing: Theme.Spacing.md) {
            LabeledIntStepper(
                label: "Hours",
                value: $viewModel.raceTargetTimeHours,
                range: 0...100,
                unit: "h"
            )
            LabeledIntStepper(
                label: "Min",
                value: $viewModel.raceTargetTimeMinutes,
                range: 0...59,
                unit: "m"
            )
        }
    }

    private var terrainSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Terrain Difficulty")
                .font(.headline)
            Picker("Terrain", selection: $viewModel.raceTerrainDifficulty) {
                ForEach(TerrainDifficulty.allCases, id: \.self) { terrain in
                    Text(terrain.rawValue.capitalized).tag(terrain)
                }
            }
            .pickerStyle(.segmented)
        }
        .cardStyle()
    }
}
