import SwiftUI

struct WatchNutritionBanner: View {
    let message: String
    let reminderType: String?
    let onDismiss: () -> Void

    var body: some View {
        Button(action: onDismiss) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.caption)
                Text(message)
                    .font(.caption2)
                    .lineLimit(2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(.blue.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
        .padding(.top, 2)
    }

    private var iconName: String {
        switch reminderType {
        case "hydration": return "drop.fill"
        case "fuel": return "fork.knife"
        case "electrolyte": return "bolt.fill"
        default: return "bell.fill"
        }
    }
}
