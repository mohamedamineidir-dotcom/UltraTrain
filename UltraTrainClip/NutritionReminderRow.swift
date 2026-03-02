import SwiftUI

struct NutritionReminderRow: View {
    let reminder: NutritionTimerViewModel.TimerReminder
    let elapsedSeconds: TimeInterval

    var body: some View {
        HStack {
            Image(systemName: reminder.type.icon)
                .foregroundStyle(colorForType)
                .frame(width: 24)

            Text(reminder.message)
                .font(.subheadline)

            Spacer()

            Text(formattedTime)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .opacity(reminder.isTriggered ? 0.5 : 1.0)
    }

    private var colorForType: Color {
        switch reminder.type {
        case .hydration: .blue
        case .fuel: .orange
        case .electrolyte: .purple
        }
    }

    private var formattedTime: String {
        let seconds = Int(reminder.triggerTimeSeconds)
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return h > 0 ? String(format: "%d:%02d", h, m) : "\(m)m"
    }
}
