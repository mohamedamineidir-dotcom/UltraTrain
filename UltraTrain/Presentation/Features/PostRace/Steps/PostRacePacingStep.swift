import SwiftUI

struct PostRacePacingStep: View {
    @Bindable var viewModel: PostRaceWizardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            assessmentSection
            notesSection
        }
    }

    // MARK: - Assessment

    private var assessmentSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("How Was Your Pacing?")
                .font(.headline)

            VStack(spacing: Theme.Spacing.sm) {
                pacingButton(
                    assessment: .tooFast,
                    icon: "hare.fill",
                    title: "Too Fast",
                    subtitle: "Started too fast, paid for it later"
                )
                pacingButton(
                    assessment: .tooSlow,
                    icon: "tortoise.fill",
                    title: "Too Slow",
                    subtitle: "Too conservative, had more to give"
                )
                pacingButton(
                    assessment: .wellPaced,
                    icon: "checkmark.seal.fill",
                    title: "Well Paced",
                    subtitle: "Good pacing throughout"
                )
                pacingButton(
                    assessment: .mixedPacing,
                    icon: "arrow.up.arrow.down",
                    title: "Mixed",
                    subtitle: "Inconsistent pacing, some good and bad"
                )
            }
        }
    }

    private func pacingButton(
        assessment: PacingAssessment,
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {
        let isSelected = viewModel.pacingAssessment == assessment
        return Button {
            viewModel.pacingAssessment = assessment
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 32)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.Colors.primary)
                        .accessibilityHidden(true)
                }
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .fill(
                        isSelected
                            ? Theme.Colors.primary.opacity(0.15)
                            : Theme.Colors.secondaryBackground
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .stroke(
                        isSelected ? Theme.Colors.primary : .clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(subtitle)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("pacing_\(assessment.rawValue)")
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Pacing Notes (Optional)")
                .font(.headline)
            TextField(
                "Any pacing insights or details?",
                text: $viewModel.pacingNotes,
                axis: .vertical
            )
            .lineLimit(2...4)
            .textFieldStyle(.roundedBorder)
            .accessibilityLabel("Pacing notes")
            .accessibilityHint("Optionally add details about your pacing strategy")
        }
    }
}
