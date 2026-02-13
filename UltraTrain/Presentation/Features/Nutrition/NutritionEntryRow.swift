import SwiftUI

struct NutritionEntryRow: View {
    let entry: NutritionEntry

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: entry.product.type.icon)
                .foregroundStyle(entry.product.type.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.product.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let notes = entry.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedTiming)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("\(entry.product.caloriesPerServing * entry.quantity) kcal")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private var formattedTiming: String {
        let hours = entry.timingMinutes / 60
        let minutes = entry.timingMinutes % 60
        if hours > 0 {
            return String(format: "%dh%02d", hours, minutes)
        }
        return "\(minutes)min"
    }
}

// MARK: - ProductType Display Extensions

extension ProductType {
    var icon: String {
        switch self {
        case .gel:      "drop.fill"
        case .bar:      "rectangle.fill"
        case .drink:    "cup.and.saucer.fill"
        case .chew:     "circle.grid.2x2.fill"
        case .realFood: "carrot.fill"
        case .salt:     "pill.fill"
        }
    }

    var color: Color {
        switch self {
        case .gel:      .blue
        case .bar:      .brown
        case .drink:    .cyan
        case .chew:     .orange
        case .realFood: .green
        case .salt:     .gray
        }
    }

    var displayName: String {
        switch self {
        case .gel:      "Gel"
        case .bar:      "Bar"
        case .drink:    "Drink"
        case .chew:     "Chew"
        case .realFood: "Real Food"
        case .salt:     "Salt"
        }
    }
}
