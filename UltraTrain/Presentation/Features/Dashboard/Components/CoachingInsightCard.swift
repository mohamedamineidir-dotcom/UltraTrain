import SwiftUI

struct CoachingInsightCard: View {
    let insights: [CoachingInsight]

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(insights) { insight in
                insightRow(insight)
            }
        }
    }

    private func insightRow(_ insight: CoachingInsight) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: insight.icon)
                    .foregroundStyle(categoryColor(insight.category))
                    .accessibilityHidden(true)
                Text(insight.title)
                    .font(.subheadline.bold())
            }

            Text(insight.message)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(categoryColor(insight.category).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(categoryColor(insight.category).opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(insight.title). \(insight.message)")
    }

    private func categoryColor(_ category: InsightCategory) -> Color {
        switch category {
        case .positive: Theme.Colors.success
        case .guidance: Theme.Colors.primary
        case .warning: Theme.Colors.warning
        }
    }
}
