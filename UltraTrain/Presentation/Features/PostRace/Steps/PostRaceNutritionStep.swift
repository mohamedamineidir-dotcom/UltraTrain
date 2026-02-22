import SwiftUI

struct PostRaceNutritionStep: View {
    @Bindable var viewModel: PostRaceWizardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            assessmentSection
            stomachSection
            notesSection
        }
    }

    // MARK: - Assessment

    private var assessmentSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("How Was Your Nutrition?")
                .font(.headline)

            VStack(spacing: Theme.Spacing.sm) {
                nutritionButton(
                    assessment: .perfect,
                    icon: "star.fill",
                    title: "Perfect",
                    subtitle: "Everything went as planned"
                )
                nutritionButton(
                    assessment: .goodEnough,
                    icon: "hand.thumbsup.fill",
                    title: "Good Enough",
                    subtitle: "Minor issues but managed well"
                )
                nutritionButton(
                    assessment: .someIssues,
                    icon: "exclamationmark.triangle.fill",
                    title: "Some Issues",
                    subtitle: "Had to adjust plan significantly"
                )
                nutritionButton(
                    assessment: .majorProblems,
                    icon: "xmark.octagon.fill",
                    title: "Major Problems",
                    subtitle: "Nutrition was a major issue"
                )
            }
        }
    }

    private func nutritionButton(
        assessment: NutritionAssessment,
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {
        let isSelected = viewModel.nutritionAssessment == assessment
        return Button {
            viewModel.nutritionAssessment = assessment
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
        .accessibilityIdentifier("nutrition_\(assessment.rawValue)")
    }

    // MARK: - Stomach Issues

    private var stomachSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Toggle(isOn: $viewModel.hadStomachIssues) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "stomach")
                        .foregroundStyle(viewModel.hadStomachIssues ? Theme.Colors.warning : Theme.Colors.secondaryLabel)
                        .accessibilityHidden(true)
                    Text("Had Stomach Issues")
                        .font(.subheadline)
                }
            }
            .tint(Theme.Colors.primary)
            .accessibilityIdentifier("stomach_issues_toggle")
        }
        .cardStyle()
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Nutrition Notes (Optional)")
                .font(.headline)
            TextField(
                "What worked or did not work?",
                text: $viewModel.nutritionNotes,
                axis: .vertical
            )
            .lineLimit(2...4)
            .textFieldStyle(.roundedBorder)
            .accessibilityLabel("Nutrition notes")
            .accessibilityHint("Optionally add details about your nutrition strategy")
        }
    }
}
