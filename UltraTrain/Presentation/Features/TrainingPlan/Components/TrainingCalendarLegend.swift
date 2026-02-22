import SwiftUI

struct TrainingCalendarLegend: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.md) {
                legendItem("Completed", color: Theme.Colors.success)
                legendItem("Partial", color: Theme.Colors.warning)
                legendItem("Planned", color: Theme.Colors.primary)
                legendItem("Unplanned", color: .blue)
                legendItem("Rest", color: Theme.Colors.secondaryLabel)
            }
            .padding(.horizontal, Theme.Spacing.sm)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Calendar legend: green for completed, yellow for partial, blue for planned, light blue for unplanned, gray for rest")
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
    }
}
