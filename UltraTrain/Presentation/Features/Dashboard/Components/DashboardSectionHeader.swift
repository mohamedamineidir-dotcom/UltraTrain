import SwiftUI

struct DashboardSectionHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Theme.Colors.accentColor)
                .frame(width: 3, height: 18)
            Text(title)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.md)
    }
}
