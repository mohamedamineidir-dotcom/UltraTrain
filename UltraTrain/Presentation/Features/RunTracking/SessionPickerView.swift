import SwiftUI

struct SessionPickerView: View {
    let sessions: [TrainingSession]
    @Binding var selectedSession: TrainingSession?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Today's Sessions")
                .font(.headline)

            ForEach(sessions) { session in
                SessionPickerRow(
                    session: session,
                    isSelected: selectedSession?.id == session.id
                )
                .onTapGesture {
                    if selectedSession?.id == session.id {
                        selectedSession = nil
                    } else {
                        selectedSession = session
                    }
                }
            }
        }
    }
}

private struct SessionPickerRow: View {
    @Environment(\.unitPreference) private var units
    let session: TrainingSession
    let isSelected: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryLabel)
                .font(.title3)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(session.type.rawValue.capitalized)
                    .font(.subheadline.bold())

                HStack(spacing: Theme.Spacing.sm) {
                    Label(
                        UnitFormatter.formatDistance(session.plannedDistanceKm, unit: units),
                        systemImage: "arrow.left.arrow.right"
                    )
                    if session.plannedElevationGainM > 0 {
                        Label(
                            "+\(UnitFormatter.formatElevation(session.plannedElevationGainM, unit: units))",
                            systemImage: "arrow.up.right"
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            Text(session.intensity.rawValue.capitalized)
                .font(.caption2.bold())
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(intensityColor.opacity(0.15))
                .foregroundStyle(intensityColor)
                .clipShape(Capsule())
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(isSelected ? Theme.Colors.primary.opacity(0.08) : Theme.Colors.secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(isSelected ? Theme.Colors.primary : .clear, lineWidth: 1.5)
        )
    }

    private var intensityColor: Color {
        switch session.intensity {
        case .easy: Theme.Colors.success
        case .moderate: Theme.Colors.warning
        case .hard: Theme.Colors.danger
        case .maxEffort: Theme.Colors.zone5
        }
    }
}
