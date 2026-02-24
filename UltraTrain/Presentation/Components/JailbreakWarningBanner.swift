import SwiftUI

struct JailbreakWarningBanner: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "shield.slash.fill")
                .font(.title2)
                .foregroundStyle(Theme.Colors.danger)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Security Warning")
                    .font(.headline)
                    .foregroundStyle(Theme.Colors.label)
                Text("This device may be compromised. Your training and health data could be at risk.")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.danger.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .padding(.horizontal, Theme.Spacing.md)
    }
}
