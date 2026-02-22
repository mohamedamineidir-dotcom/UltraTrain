import SwiftUI

struct PacingAlertBanner: View {
    let alert: PacingAlert
    let onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)

            Text(alert.message)
                .font(.subheadline.bold())
                .foregroundStyle(Theme.Colors.label)
                .lineLimit(2)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(Theme.Spacing.xs)
                    .background(Theme.Colors.secondaryLabel)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Dismiss")
            .accessibilityHint("Dismiss pacing alert")
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        )
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .onAppear {
            AccessibilityNotification.Announcement(alert.message).post()
        }
    }

    // MARK: - Styling

    private var iconName: String {
        switch alert.type {
        case .tooFast: "hare.fill"
        case .tooSlow: "tortoise.fill"
        case .backOnPace: "checkmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch alert.severity {
        case .major: Theme.Colors.danger
        case .minor: Theme.Colors.warning
        case .positive: Theme.Colors.success
        }
    }

    private var backgroundColor: Color {
        switch alert.severity {
        case .major: Theme.Colors.danger.opacity(0.12)
        case .minor: Theme.Colors.warning.opacity(0.12)
        case .positive: Theme.Colors.success.opacity(0.12)
        }
    }
}
