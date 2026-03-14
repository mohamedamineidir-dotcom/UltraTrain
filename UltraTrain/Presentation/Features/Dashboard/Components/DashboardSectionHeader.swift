import SwiftUI

struct DashboardSectionHeader: View {
    let title: String
    @State private var lineWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title.uppercased())
                .font(.caption.bold())
                .tracking(Theme.LetterSpacing.tracked)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.accentColor, Theme.Colors.accentColor.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: lineWidth, height: 1.5)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.6)) {
                        lineWidth = 60
                    }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.lg)
    }
}
