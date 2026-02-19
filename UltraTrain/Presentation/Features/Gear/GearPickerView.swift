import SwiftUI

struct GearPickerView: View {
    let gearItems: [GearItem]
    @Binding var selectedGearIds: Set<UUID>

    var body: some View {
        if gearItems.isEmpty { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Gear")
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .padding(.horizontal, Theme.Spacing.md)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(gearItems) { item in
                            gearChip(item)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
            }
        )
    }

    private func gearChip(_ item: GearItem) -> some View {
        let isSelected = selectedGearIds.contains(item.id)
        return Button {
            if isSelected {
                selectedGearIds.remove(item.id)
            } else {
                selectedGearIds.insert(item.id)
            }
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                Text(item.name)
                    .font(.caption)
                if item.needsReplacement {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .fill(isSelected ? Theme.Colors.primary.opacity(0.15) : Theme.Colors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .stroke(isSelected ? Theme.Colors.primary : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
