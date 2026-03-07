import SwiftUI

struct RaceProfileStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    private var isImperial: Bool { viewModel.preferredUnit == .imperial }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xxl) {
                // Header
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.accentColor)

                    Text("Race Profile")
                        .font(.title.bold())

                    Text("Tell us about the course.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.xl)

                VStack(spacing: Theme.Spacing.lg) {
                    LabeledStepper(
                        label: "Distance",
                        value: distanceBinding,
                        range: isImperial ? 1...310 : 1...500,
                        step: isImperial ? 3 : 5,
                        unit: UnitFormatter.distanceLabel(viewModel.preferredUnit)
                    )
                    .cardStyle()

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

                    // Terrain
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

                    trainingDurationWarning
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
        }
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
}
