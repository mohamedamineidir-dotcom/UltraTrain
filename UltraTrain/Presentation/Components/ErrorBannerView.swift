import SwiftUI

struct ErrorBannerView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.Colors.warning)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.label)
            Spacer()
            if let retryAction {
                Button("Retry", action: retryAction)
                    .font(.subheadline.bold())
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
    }
}
