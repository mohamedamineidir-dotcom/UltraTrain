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

    private var isImperial: Bool { viewModel.preferredUnit == .imperial }

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
                value: distanceBinding,
                range: isImperial ? 1...310 : 1...500,
                step: isImperial ? 3 : 5,
                unit: UnitFormatter.distanceLabel(viewModel.preferredUnit)
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
                value: elevationGainBinding,
                range: isImperial ? 0...65600 : 0...20000,
                step: isImperial ? 300 : 100,
                unit: UnitFormatter.elevationShortLabel(viewModel.preferredUnit)
            )
            Divider()
            LabeledStepper(
                label: "D- (loss)",
                value: elevationLossBinding,
                range: isImperial ? 0...65600 : 0...20000,
                step: isImperial ? 300 : 100,
                unit: UnitFormatter.elevationShortLabel(viewModel.preferredUnit)
            )
        }
        .cardStyle()
    }

    private var distanceBinding: Binding<Double> {
        isImperial
            ? Binding(
                get: { UnitFormatter.distanceValue(viewModel.raceDistanceKm, unit: .imperial) },
                set: { viewModel.raceDistanceKm = UnitFormatter.distanceToKm($0, unit: .imperial) }
            )
            : $viewModel.raceDistanceKm
    }

    private var elevationGainBinding: Binding<Double> {
        isImperial
            ? Binding(
                get: { UnitFormatter.elevationValue(viewModel.raceElevationGainM, unit: .imperial) },
                set: { viewModel.raceElevationGainM = UnitFormatter.elevationToMeters($0, unit: .imperial) }
            )
            : $viewModel.raceElevationGainM
    }

    private var elevationLossBinding: Binding<Double> {
        isImperial
            ? Binding(
                get: { UnitFormatter.elevationValue(viewModel.raceElevationLossM, unit: .imperial) },
                set: { viewModel.raceElevationLossM = UnitFormatter.elevationToMeters($0, unit: .imperial) }
            )
            : $viewModel.raceElevationLossM
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
            .accessibilityHint("Choose your race goal: finish, target time, or target ranking")

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
            .accessibilityHint("Select the terrain difficulty of your race course")
        }
        .cardStyle()
    }
}
