import SwiftUI

struct OrDividerView: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Rectangle()
                .fill(Theme.Colors.tertiaryLabel.opacity(0.3))
                .frame(height: 1)
            Text("or")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Rectangle()
                .fill(Theme.Colors.tertiaryLabel.opacity(0.3))
                .frame(height: 1)
        }
    }
}
