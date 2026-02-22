import SwiftUI

struct ZoneDriftAlertBanner: View {
    let alert: ZoneDriftAlertCalculator.ZoneDriftAlert
    let onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(.white)
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
            .accessibilityHint("Dismiss heart rate zone alert")
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
        .task {
            try? await Task.sleep(for: .seconds(8))
            onDismiss()
        }
    }

    // MARK: - Styling

    private var iconName: String {
        alert.currentZone > alert.targetZone ? "arrow.down.heart.fill" : "arrow.up.heart.fill"
    }

    private var backgroundColor: Color {
        switch alert.severity {
        case .mild: Color.yellow.opacity(0.15)
        case .moderate: Color.orange.opacity(0.15)
        case .significant: Color.red.opacity(0.15)
        }
    }
}
