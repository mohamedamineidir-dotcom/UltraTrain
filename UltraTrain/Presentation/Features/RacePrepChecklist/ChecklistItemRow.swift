import SwiftUI

struct ChecklistItemRow: View {
    let item: ChecklistItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isChecked ? Theme.Colors.success : Theme.Colors.secondaryLabel)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline)
                        .foregroundStyle(item.isChecked ? Theme.Colors.secondaryLabel : Theme.Colors.label)
                        .strikethrough(item.isChecked)

                    if let notes = item.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }

                Spacer()

                if item.isCustom {
                    Text("Custom")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.Colors.secondaryLabel.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.vertical, Theme.Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
