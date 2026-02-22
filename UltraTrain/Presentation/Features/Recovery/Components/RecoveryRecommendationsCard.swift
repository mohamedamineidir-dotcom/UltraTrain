import SwiftUI

struct RecoveryRecommendationsCard: View {
    let recommendations: [RecoveryRecommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Recommendations")
                .font(.headline)

            ForEach(recommendations) { recommendation in
                recommendationRow(recommendation)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
        .padding(.horizontal, Theme.Spacing.md)
    }

    private func recommendationRow(_ recommendation: RecoveryRecommendation) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: recommendation.iconName)
                .font(.title3)
                .foregroundStyle(priorityColor(recommendation.priority))
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.title)
                    .font(.subheadline.bold())
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .accessibilityElement(children: .combine)
    }

    private func priorityColor(_ priority: RecommendationPriority) -> Color {
        switch priority {
        case .high: Theme.Colors.danger
        case .medium: Theme.Colors.warning
        case .low: Theme.Colors.success
        }
    }
}
