import SwiftUI

struct GoalTrainingStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xxl) {
                // Header
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "target")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.accentColor)

                    Text("Goal & Training")
                        .font(.title.bold())

                    Text("How should we build your plan?")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.xl)

                VStack(spacing: Theme.Spacing.lg) {
                    // Goal type
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Race Goal")
                            .font(.headline)
                        Picker("Goal Type", selection: $viewModel.raceGoalType) {
                            ForEach(RaceGoalSelection.allCases, id: \.self) { goal in
                                Text(goal.displayName).tag(goal)
                            }
                        }
                        .pickerStyle(.segmented)

                        if viewModel.raceGoalType == .targetTime {
                            HStack(spacing: Theme.Spacing.md) {
                                LabeledIntStepper(label: "Hours", value: $viewModel.raceTargetTimeHours, range: 0...100, unit: "h")
                                LabeledIntStepper(label: "Min", value: $viewModel.raceTargetTimeMinutes, range: 0...59, unit: "m")
                            }
                        }
                        if viewModel.raceGoalType == .targetRanking {
                            LabeledIntStepper(label: "Target Position", value: $viewModel.raceTargetRanking, range: 1...5000, unit: "")
                        }
                    }
                    .cardStyle()
                    .animation(.easeInOut(duration: 0.2), value: viewModel.raceGoalType)

                    goalRealisticnessWarning

                    // Training philosophy
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Training Style")
                            .font(.headline)

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

                    // Runs per week
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Runs Per Week")
                            .font(.headline)
                        LabeledIntStepper(
                            label: "Sessions",
                            value: $viewModel.preferredRunsPerWeek,
                            range: 3...7,
                            unit: "runs"
                        )
                        Text("3 runs minimum. Extra days become rest days.")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                    .cardStyle()
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
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
}
