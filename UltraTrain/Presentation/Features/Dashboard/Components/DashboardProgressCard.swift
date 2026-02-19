import SwiftUI

struct DashboardProgressCard: View {
    let runCount: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Training Progress")
                    .font(.headline)
                    .foregroundStyle(Theme.Colors.label)
                Text("\(runCount) runs logged")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
            Image(systemName: "chart.bar.fill")
                .foregroundStyle(Theme.Colors.primary)
                .accessibilityHidden(true)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityHidden(true)
        }
        .cardStyle()
    }
}
