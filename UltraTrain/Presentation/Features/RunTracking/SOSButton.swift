import SwiftUI

struct SOSButton: View {
    let onActivate: () -> Void

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let buttonSize: CGFloat = 56

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            sosCircle
            holdLabel
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("SOS")
        .accessibilityHint("Long press for one and a half seconds to send emergency alert")
    }

    // MARK: - Subviews

    private var sosCircle: some View {
        Text("SOS")
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: buttonSize, height: buttonSize)
            .background(
                Circle()
                    .fill(Theme.Colors.danger)
                    .shadow(
                        color: Theme.Colors.danger.opacity(isPressed ? 0.5 : 0.3),
                        radius: isPressed ? 12 : 6,
                        y: isPressed ? 2 : 4
                    )
            )
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(
                reduceMotion ? .none : .easeInOut(duration: 0.15),
                value: isPressed
            )
            .gesture(longPressGesture)
    }

    private var holdLabel: some View {
        Text("Hold for SOS")
            .font(.caption2)
            .foregroundStyle(Theme.Colors.secondaryLabel)
    }

    // MARK: - Gesture

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: AppConfiguration.Safety.sosLongPressSeconds)
            .onChanged { isPressing in
                isPressed = isPressing
            }
            .onEnded { completed in
                isPressed = false
                if completed {
                    onActivate()
                }
            }
    }
}

#Preview {
    SOSButton {
        // no-op
    }
    .padding()
}
