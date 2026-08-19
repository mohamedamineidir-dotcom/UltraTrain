import SwiftUI

struct PostRaceIndexUpdateStep: View {
    @Bindable var viewModel: PostRaceWizardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            introSection
            indexField(title: "ITRA Index", input: $viewModel.itraIndexInput)
            indexField(title: "UTMB Index", input: $viewModel.utmbIndexInput)
        }
    }

    private var introSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Did this race update your index?")
                .font(.headline)
            Text("If your ITRA or UTMB index changed after this race, update it here — it helps sharpen future finish-time predictions. Leave blank if unchanged or unknown.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    private func indexField(title: String, input: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(LocalizedStringKey(title))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.Colors.secondaryLabel)
            TextField("Optional", text: input)
                .keyboardType(.numberPad)
                .font(.body.monospacedDigit())
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 140)
        }
        .cardStyle()
    }
}
