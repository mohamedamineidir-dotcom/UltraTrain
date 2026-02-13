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
            TextField("Last Name", text: $viewModel.lastName)
                .textContentType(.familyName)
                .autocorrectionDisabled()
        }
        .textFieldStyle(.roundedBorder)
        .cardStyle()
    }

    private var dateOfBirthSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Date of Birth")
                .font(.headline)
            DatePicker(
                "Birthday",
                selection: $viewModel.dateOfBirth,
                in: ...Date.now,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
        }
        .cardStyle()
    }

    private var bodyMetricsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Body Metrics")
                .font(.headline)
            LabeledStepper(
                label: "Weight",
                value: $viewModel.weightKg,
                range: 30...200,
                step: 0.5,
                unit: "kg"
            )
            Divider()
            LabeledStepper(
                label: "Height",
                value: $viewModel.heightCm,
                range: 100...250,
                step: 1,
                unit: "cm"
            )
        }
        .cardStyle()
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
        }
        .cardStyle()
    }
}
