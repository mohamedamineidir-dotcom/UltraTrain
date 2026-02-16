import SwiftUI

struct NutritionReminderBanner: View {
    let reminder: NutritionReminder
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(iconColor)

            Text(reminder.message)
                .font(.subheadline.bold())
                .foregroundStyle(Theme.Colors.label)
                .lineLimit(2)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .padding(Theme.Spacing.xs)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        )
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
        .transition(.move(edge: .top).combined(with: .opacity))
        .task {
            try? await Task.sleep(for: .seconds(AppConfiguration.NutritionReminders.autoDismissSeconds))
            onDismiss()
        }
    }

    // MARK: - Styling

    private var iconName: String {
        switch reminder.type {
        case .hydration: "drop.fill"
        case .fuel: "bolt.fill"
        case .electrolyte: "leaf.fill"
        }
    }

    private var iconColor: Color {
        switch reminder.type {
        case .hydration: .blue
        case .fuel: Theme.Colors.warning
        case .electrolyte: .green
        }
    }

    private var backgroundColor: Color {
        switch reminder.type {
        case .hydration: .blue.opacity(0.12)
        case .fuel: Theme.Colors.warning.opacity(0.12)
        case .electrolyte: .green.opacity(0.12)
        }
    }
}
