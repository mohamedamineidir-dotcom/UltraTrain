import SwiftUI

struct SafetyAlertBanner: View {
    let alert: SafetyAlert
    let countdownRemaining: Int
    let onCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            alertHeader
            countdownDisplay
            cancelButton
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(backgroundGradient)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
        .padding(.horizontal, Theme.Spacing.md)
        .transition(
            reduceMotion
                ? .opacity
                : .move(edge: .top).combined(with: .opacity)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(.updatesFrequently)
        .onAppear {
            AccessibilityNotification.Announcement(accessibilityDescription).post()
        }
    }

    // MARK: - Subviews

    private var alertHeader: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: alert.type.iconName)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .accessibilityHidden(true)

            Text(alert.message)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
    }

    private var countdownDisplay: some View {
        Text("\(countdownRemaining)")
            .font(.system(size: 56, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .contentTransition(.numericText(countsDown: true))
            .animation(
                reduceMotion ? .none : .spring(duration: 0.3),
                value: countdownRemaining
            )
            .accessibilityLabel("Sending in \(countdownRemaining) seconds")
    }

    private var cancelButton: some View {
        Button {
            onCancel()
        } label: {
            Text("I'm OK — Cancel")
                .font(.headline)
                .foregroundStyle(Theme.Colors.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .fill(.white)
                )
        }
        .accessibilityLabel("Cancel emergency alert")
        .accessibilityHint("Tap to cancel the SOS countdown")
    }

    // MARK: - Styling

    private var backgroundGradient: some ShapeStyle {
        LinearGradient(
            colors: [
                Theme.Colors.danger,
                Theme.Colors.danger.opacity(0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        "\(alert.type.displayName) alert. \(alert.message). Sending in \(countdownRemaining) seconds. Tap cancel if you are okay."
    }
}

#Preview {
    SafetyAlertBanner(
        alert: SafetyAlert(
            id: UUID(),
            type: .fallDetected,
            triggeredAt: .now,
            latitude: 45.832,
            longitude: 6.865,
            message: "Fall detected — emergency contacts will be notified.",
            status: .triggered
        ),
        countdownRemaining: 25,
        onCancel: {}
    )
    .padding(.top, Theme.Spacing.xl)
}
