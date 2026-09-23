#if OWNER_MODE
import SwiftUI

/// One editable block (interval phase) card: phase type, duration-or-
/// distance trigger, intensity, repeat count, notes, plus move/delete
/// controls. Used inside `OwnerSessionEditSheet`'s block editor list.
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
            triggerRow
            HStack(spacing: Theme.Spacing.md) {
                intensityMenu
                repeatStepper
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

    private var triggerRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Picker("", selection: $block.isDurationTrigger) {
                Text("Duration").tag(true)
                Text("Distance").tag(false)
            }
            .pickerStyle(.segmented)
            .frame(width: 180)

            if block.isDurationTrigger {
                Stepper(value: $block.minutes, in: 0...180) {
                    Text("\(block.minutes)m")
                        .font(.subheadline.monospacedDigit())
                }
                Stepper(value: $block.seconds, in: 0...55, step: 5) {
                    Text("\(block.seconds)s")
                        .font(.subheadline.monospacedDigit())
                }
            } else {
                Stepper(value: $block.distanceKm, in: 0.1...42, step: 0.1) {
                    Text(String(format: "%.1f km", block.distanceKm))
                        .font(.subheadline.monospacedDigit())
                }
            }
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

    private var repeatStepper: some View {
        Stepper(value: $block.repeatCount, in: 1...20) {
            Text("\(block.repeatCount)x")
                .font(.caption.bold().monospacedDigit())
        }
    }
}
#endif
