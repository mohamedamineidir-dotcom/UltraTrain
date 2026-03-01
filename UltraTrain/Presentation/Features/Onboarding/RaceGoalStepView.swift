import SwiftUI

struct RaceGoalStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerSection
                raceInfoSection
                elevationSection
                trainingDurationWarning
                goalTypeSection
                goalRealisticnessWarning
                terrainSection
                trainingPhilosophySection
                runsPerWeekSection
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
            RaceAutoCompleteField(text: $viewModel.raceName) { race in
                viewModel.raceDistanceKm = race.distanceKm
                viewModel.raceElevationGainM = race.elevationGainM
                viewModel.raceElevationLossM = race.elevationLossM
            }
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

    @ViewBuilder
    private var trainingDurationWarning: some View {
        let validation = TrainingDurationValidator.validate(
            distanceKm: viewModel.raceDistanceKm,
            elevationGainM: viewModel.raceElevationGainM,
            raceDate: viewModel.raceDate,
            experienceLevel: viewModel.experienceLevel ?? .beginner
        )
        if let message = validation.warningMessage {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Theme.Colors.warning)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.warning.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
        }
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

    @ViewBuilder
    private var goalRealisticnessWarning: some View {
        let validation: GoalValidation? = {
            let level = viewModel.experienceLevel ?? .beginner
            switch viewModel.raceGoalType {
            case .finish:
                return nil
            case .targetTime:
                let seconds = TimeInterval(viewModel.raceTargetTimeHours * 3600 + viewModel.raceTargetTimeMinutes * 60)
                guard seconds > 0 else { return nil }
                return GoalRealisticnessValidator.validateTime(
                    targetTimeSeconds: seconds,
                    distanceKm: viewModel.raceDistanceKm,
                    elevationGainM: viewModel.raceElevationGainM,
                    experienceLevel: level
                )
            case .targetRanking:
                guard viewModel.raceTargetRanking > 0 else { return nil }
                return GoalRealisticnessValidator.validateRanking(
                    targetRanking: viewModel.raceTargetRanking,
                    distanceKm: viewModel.raceDistanceKm,
                    elevationGainM: viewModel.raceElevationGainM,
                    experienceLevel: level
                )
            }
        }()
        if let message = validation?.warningMessage {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Theme.Colors.warning)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.warning.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
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

    private var trainingPhilosophySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Training Style")
                .font(.headline)
            Text("How do you want to approach your training?")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            ForEach(TrainingPhilosophy.allCases, id: \.self) { philosophy in
                Button {
                    viewModel.trainingPhilosophy = philosophy
                } label: {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: philosophy.iconName)
                            .font(.title2)
                            .foregroundStyle(viewModel.trainingPhilosophy == philosophy ? .white : Theme.Colors.primary)
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(philosophy.displayName)
                                .font(.subheadline.bold())
                            Text(philosophy.subtitle)
                                .font(.caption)
                                .foregroundStyle(viewModel.trainingPhilosophy == philosophy ? .white.opacity(0.85) : Theme.Colors.secondaryLabel)
                        }

                        Spacer()

                        if viewModel.trainingPhilosophy == philosophy {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(Theme.Spacing.md)
                    .background(
                        viewModel.trainingPhilosophy == philosophy
                            ? AnyShapeStyle(Theme.Colors.primary)
                            : AnyShapeStyle(Theme.Colors.secondaryBackground)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                }
                .buttonStyle(.plain)
            }
        }
        .cardStyle()
        .animation(.easeInOut(duration: 0.2), value: viewModel.trainingPhilosophy)
    }

    private var runsPerWeekSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Runs Per Week")
                .font(.headline)
            LabeledIntStepper(
                label: "Sessions",
                value: $viewModel.preferredRunsPerWeek,
                range: 3...6,
                unit: "runs"
            )
            Text("Extra days become rest days. 3 runs minimum to maintain fitness.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .cardStyle()
    }
}
