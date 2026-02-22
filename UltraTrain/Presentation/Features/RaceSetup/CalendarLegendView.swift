import SwiftUI

struct CalendarLegendView: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.md) {
                ForEach(TrainingPhase.allCases, id: \.self) { phase in
                    legendItem(phase.displayName, color: phase.color)
                }

                Divider()
                    .frame(height: 12)

                legendItem("A Race", color: Theme.Colors.danger)
                legendItem("B Race", color: Theme.Colors.warning)
                legendItem("C Race", color: Theme.Colors.secondaryLabel)
            }
            .padding(.horizontal, Theme.Spacing.sm)
        }
    }

    private func legendItem(_ label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .accessibilityElement(children: .combine)
    }
}
