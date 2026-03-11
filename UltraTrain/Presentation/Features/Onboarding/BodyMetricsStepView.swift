import SwiftUI

struct BodyMetricsStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    private var isImperial: Bool { viewModel.preferredUnit == .imperial }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xxl) {
                // Header
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(Circle().fill(Theme.Gradients.warmCoralCTA))
                        .shadow(color: Theme.Colors.warmCoral.opacity(0.3), radius: 8, y: 4)

                    Text("Body Metrics")
                        .font(.title.bold())

                    Text("Helps us calibrate your training zones and nutrition.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.xl)

                // Metrics
                VStack(spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Biological Sex")
                            .font(.headline)
                        Text("Used for accurate calorie calculations.")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                        Picker("Biological Sex", selection: $viewModel.biologicalSex) {
                            Text("Male").tag(BiologicalSex.male)
                            Text("Female").tag(BiologicalSex.female)
                        }
                        .pickerStyle(.segmented)
                    }
                    .onboardingCardStyle()

                    LabeledStepper(
                        label: "Weight",
                        value: weightBinding,
                        range: isImperial ? 66...440 : 30...200,
                        step: isImperial ? 1 : 0.5,
                        unit: UnitFormatter.weightLabel(viewModel.preferredUnit)
                    )
                    .onboardingCardStyle()

                    LabeledStepper(
                        label: "Height",
                        value: heightBinding,
                        range: isImperial ? 39...98 : 100...250,
                        step: 1,
                        unit: isImperial ? "in" : "cm"
                    )
                    .onboardingCardStyle()

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Weight Goal")
                            .font(.headline)
                        Text("Adjusts your daily calorie targets.")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                        Picker("Weight Goal", selection: $viewModel.weightGoal) {
                            Text("Lose").tag(WeightGoal.lose)
                            Text("Maintain").tag(WeightGoal.maintain)
                            Text("Gain").tag(WeightGoal.gain)
                        }
                        .pickerStyle(.segmented)
                    }
                    .onboardingCardStyle()
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
        }
    }

    private var weightBinding: Binding<Double> {
        isImperial
            ? Binding(
                get: { UnitFormatter.weightValue(viewModel.weightKg, unit: .imperial) },
                set: { viewModel.weightKg = UnitFormatter.weightToKg($0, unit: .imperial) }
            )
            : $viewModel.weightKg
    }

    private var heightBinding: Binding<Double> {
        isImperial
            ? Binding(
                get: { (viewModel.heightCm / 2.54).rounded() },
                set: { viewModel.heightCm = $0 * 2.54 }
            )
            : $viewModel.heightCm
    }
}
