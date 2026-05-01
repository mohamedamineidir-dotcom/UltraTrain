import SwiftUI

struct SkipReasonSheet: View {
    let sessionType: SessionType
    let onConfirm: (SkipReason) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: SkipReason?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Text("Why are you skipping this session?")
                        .font(.headline)
                        .padding(.horizontal, Theme.Spacing.md)

                    Text("This helps us adapt your training plan intelligently.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .padding(.horizontal, Theme.Spacing.md)

                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(SkipReason.allCases, id: \.self) { reason in
                            reasonRow(reason)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
                .padding(.vertical, Theme.Spacing.md)
            }
            .navigationTitle("Skip Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Skip") {
                        if let reason = selectedReason {
                            onConfirm(reason)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedReason == nil)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Reason Row

    private func reasonRow(_ reason: SkipReason) -> some View {
        let isSelected = selectedReason == reason
        return Button {
            selectedReason = reason
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: reason.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : reason.color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(reason.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isSelected ? .white : Theme.Colors.label)

                    Text(reason.hint)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : Theme.Colors.secondaryLabel)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(isSelected ? reason.color : Theme.Colors.secondaryBackground)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(reason.displayName)
        .accessibilityHint(reason.hint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - SkipReason UI Properties

extension SkipReason {
    var displayName: String {
        switch self {
        case .noTime:         "I don't have time"
        case .fatigue:        "I feel tired or fatigued"
        case .noMotivation:   "No motivation today"
        case .soreness:       "Muscle soreness or pain"
        case .illness:        "Feeling unwell or sick"
        case .weather:        "Bad weather or conditions"
        case .injury:         "I have an injury or sharp pain"
        case .other:          "Other reason"
        case .menstrualCycle: "Menstrual cycle / period symptoms"
        }
    }

    var hint: String {
        switch self {
        case .noTime:         "Work, family, or schedule conflict"
        case .fatigue:        "Legs heavy, body tired, need rest"
        case .noMotivation:   "Mentally not feeling it today"
        case .soreness:       "Joint discomfort or muscle tightness"
        case .illness:        "Cold, flu, or general malaise"
        case .injury:         "Strain, sprain, or acute pain"
        case .weather:        "Rain, extreme heat, unsafe trail"
        case .other:          "Something else"
        case .menstrualCycle: "Cramps, heavy flow, PMS, or related symptoms"
        }
    }

    var icon: String {
        switch self {
        case .noTime:         "clock"
        case .fatigue:        "battery.25percent"
        case .noMotivation:   "brain.head.profile"
        case .soreness:       "bandage"
        case .illness:        "cross.case"
        case .injury:         "exclamationmark.triangle"
        case .weather:        "cloud.rain"
        case .other:          "ellipsis.circle"
        case .menstrualCycle: "calendar.badge.clock"
        }
    }

    var color: Color {
        switch self {
        case .noTime:         .blue
        case .fatigue:        .orange
        case .noMotivation:   .purple
        case .soreness:       .red
        case .illness:        .pink
        case .injury:         .red
        case .weather:        .cyan
        case .other:          .gray
        case .menstrualCycle: .indigo
        }
    }
}
