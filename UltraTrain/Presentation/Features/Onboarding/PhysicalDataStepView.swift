import SwiftUI

struct PhysicalDataStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerSection
                nameSection
                dateOfBirthSection
                bodyMetricsSection
                heartRateSection
            }
            .padding()
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Your Physical Data")
                .font(.title2.bold())
            Text("Used to personalize training intensity and nutrition.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Name")
                .font(.headline)
            TextField("First Name", text: $viewModel.firstName)
                .textContentType(.givenName)
                .autocorrectionDisabled()
                .accessibilityIdentifier("onboarding.firstNameField")
            TextField("Last Name", text: $viewModel.lastName)
                .textContentType(.familyName)
                .autocorrectionDisabled()
                .accessibilityIdentifier("onboarding.lastNameField")
        }
        .textFieldStyle(.roundedBorder)
        .cardStyle()
    }

    private var dateOfBirthSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Date of Birth")
                .font(.headline)
            DatePicker(
                "Date of Birth",
                selection: $viewModel.dateOfBirth,
                in: ...Date.now,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .accessibilityLabel("Date of Birth")
        }
        .cardStyle()
    }

    private var bodyMetricsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Body Metrics")
                .font(.headline)
            LabeledStepper(
                label: "Weight",
                value: weightBinding,
                range: isImperial ? 66...440 : 30...200,
                step: isImperial ? 1 : 0.5,
                unit: UnitFormatter.weightLabel(viewModel.preferredUnit)
            )
            Divider()
            LabeledStepper(
                label: "Height",
                value: heightBinding,
                range: isImperial ? 39...98 : 100...250,
                step: 1,
                unit: isImperial ? "in" : "cm"
            )
        }
        .cardStyle()
    }

    private var isImperial: Bool { viewModel.preferredUnit == .imperial }

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

    private var heartRateSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Heart Rate")
                .font(.headline)
            LabeledIntStepper(
                label: "Resting HR",
                value: $viewModel.restingHeartRate,
                range: 30...120,
                unit: "bpm"
            )
            Divider()
            LabeledIntStepper(
                label: "Max HR",
                value: $viewModel.maxHeartRate,
                range: 120...230,
                unit: "bpm"
            )
            Text("Tip: If unknown, use 220 minus your age as max HR")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityLabel("Tip: If unknown, use 220 minus your age as maximum heart rate")
        }
        .cardStyle()
    }
}
