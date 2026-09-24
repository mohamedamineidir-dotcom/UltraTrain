#if OWNER_MODE
import SwiftUI

/// One editable block (interval phase) card. Every control gets its
/// own full-width row with a clear label and a always-visible value
/// (never crammed side-by-side with other controls, which is what
/// made an earlier layout confusing — steppers with no room to show
/// their own value next to several others on one line).
struct OwnerBlockRow: View {
    @Binding var block: OwnerBlockDraft
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            header

            Picker("", selection: $block.isDurationTrigger) {
                Text("Duration").tag(true)
                Text("Distance").tag(false)
            }
            .pickerStyle(.segmented)

            if block.isDurationTrigger {
                valueRow(label: "Minutes", value: "\(block.minutes)") {
                    Stepper("", value: $block.minutes, in: 0...180).labelsHidden()
                }
                valueRow(label: "Seconds", value: "\(block.seconds)") {
                    Stepper("", value: $block.seconds, in: 0...55, step: 5).labelsHidden()
                }
            } else {
                valueRow(label: "Distance (km)", value: String(format: "%.1f", block.distanceKm)) {
                    Stepper("", value: $block.distanceKm, in: 0.1...42, step: 0.1).labelsHidden()
                }
            }

            valueRow(label: "Intensity", value: nil) {
                intensityMenu
            }
            valueRow(label: "Repeat", value: "\(block.repeatCount)x") {
                Stepper("", value: $block.repeatCount, in: 1...20).labelsHidden()
            }

            TextField("Notes (shown to you on the session page)", text: $block.notes)
                .font(.caption)
                .textFieldStyle(.plain)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.xs)
                        .fill(Color.white.opacity(0.05))
                )
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(OwnerModeTheme.purple.opacity(0.25), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: block.phaseType.iconName)
                .font(.caption.bold())
                .foregroundStyle(OwnerModeTheme.purple)

            Menu {
                ForEach(IntervalPhaseType.allCases, id: \.self) { type in
                    Button(type.displayName) { block.phaseType = type }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(block.phaseType.displayName)
                        .font(.subheadline.bold())
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(.primary)
            }

            Spacer()

            Button(action: onMoveUp) {
                Image(systemName: "chevron.up.circle")
            }
            .disabled(!canMoveUp)

            Button(action: onMoveDown) {
                Image(systemName: "chevron.down.circle")
            }
            .disabled(!canMoveDown)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash.circle")
            }
        }
        .foregroundStyle(Theme.Colors.secondaryLabel)
    }

    /// A label on the left, an always-visible value (when given) next
    /// to its control on the right — nothing here ever has to shrink
    /// to fit, since it's just two short text fragments plus one small
    /// control per row.
    @ViewBuilder
    private func valueRow<Control: View>(label: String, value: String?, @ViewBuilder control: () -> Control) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Spacer()
            if let value {
                Text(value)
                    .font(.subheadline.bold().monospacedDigit())
                    .frame(minWidth: 30, alignment: .trailing)
            }
            control()
        }
    }

    private var intensityMenu: some View {
        Menu {
            ForEach(Intensity.allCases, id: \.self) { intensity in
                Button(intensity.displayName) { block.intensity = intensity }
            }
        } label: {
            HStack(spacing: 4) {
                Circle().fill(block.intensity.color).frame(width: 8, height: 8)
                Text(block.intensity.displayName)
                    .font(.caption.bold())
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
        }
    }
}
#endif
