import SwiftUI

struct PostRaceTakeawaysStep: View {
    @Bindable var viewModel: PostRaceWizardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            satisfactionSection
            takeawaysSection
        }
    }

    // MARK: - Star Rating

    private var satisfactionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Overall Satisfaction")
                .font(.headline)

            HStack(spacing: Theme.Spacing.md) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        viewModel.overallSatisfaction = star
                    } label: {
                        Image(systemName: star <= viewModel.overallSatisfaction ? "star.fill" : "star")
                            .font(.title)
                            .foregroundStyle(
                                star <= viewModel.overallSatisfaction
                                    ? Theme.Colors.warning
                                    : Theme.Colors.secondaryLabel
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
                    .accessibilityAddTraits(
                        star == viewModel.overallSatisfaction ? .isSelected : []
                    )
                    .accessibilityIdentifier("star_\(star)")
                }
            }
            .frame(maxWidth: .infinity)

            Text(satisfactionLabel)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(maxWidth: .infinity)
        }
        .cardStyle()
    }

    private var satisfactionLabel: String {
        switch viewModel.overallSatisfaction {
        case 1: return "Very Disappointed"
        case 2: return "Disappointed"
        case 3: return "Neutral"
        case 4: return "Satisfied"
        case 5: return "Very Satisfied"
        default: return ""
        }
    }

    // MARK: - Key Takeaways

    private var takeawaysSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Key Takeaways")
                .font(.headline)

            Text("What did you learn? What would you do differently?")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            TextEditor(text: $viewModel.keyTakeaways)
                .frame(minHeight: 120, maxHeight: 240)
                .padding(Theme.Spacing.xs)
                .background(Theme.Colors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .stroke(Theme.Colors.secondaryLabel.opacity(0.3), lineWidth: 1)
                )
                .accessibilityLabel("Key takeaways")
                .accessibilityHint("Write your main learnings and reflections from this race")
                .accessibilityIdentifier("key_takeaways_editor")
        }
    }
}
