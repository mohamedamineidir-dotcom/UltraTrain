import SwiftUI

struct TrainingCalendarDayCell: View {
    let date: Date
    let status: TrainingCalendarDayStatus
    let phase: TrainingPhase?
    let isSelected: Bool
    let isToday: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.callout)
                .fontDesign(.rounded)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(foregroundColor)

            statusIndicator
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, minHeight: 40)
        .background(backgroundView)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch status {
        case .completed:
            Circle()
                .fill(Theme.Colors.success)
                .frame(width: 6, height: 6)
        case .partial:
            Circle()
                .fill(Theme.Colors.warning)
                .frame(width: 6, height: 6)
        case .planned:
            Circle()
                .fill(Theme.Colors.primary)
                .frame(width: 4, height: 4)
        case .ranWithoutPlan:
            Circle()
                .fill(.blue)
                .frame(width: 5, height: 5)
        case .rest:
            Circle()
                .fill(Theme.Colors.secondaryLabel.opacity(0.4))
                .frame(width: 3, height: 3)
        case .noActivity:
            Circle()
                .fill(.clear)
                .frame(width: 4, height: 4)
        }
    }

    private var backgroundView: some View {
        ZStack {
            switch status {
            case .completed:
                Circle()
                    .fill(Theme.Colors.success.opacity(0.15))
            case .partial:
                Circle()
                    .fill(Theme.Colors.warning.opacity(0.12))
            case .ranWithoutPlan:
                Circle()
                    .fill(.blue.opacity(0.12))
            case .planned:
                if let phase {
                    Circle()
                        .fill(phase.color.opacity(0.12))
                } else {
                    Circle()
                        .fill(.clear)
                }
            default:
                Circle()
                    .fill(.clear)
            }

            if isSelected {
                Circle()
                    .strokeBorder(Theme.Colors.primary, lineWidth: 2)
            } else if isToday {
                Circle()
                    .strokeBorder(.blue, lineWidth: 1.5)
            }
        }
    }

    private var foregroundColor: Color {
        if isSelected {
            return Theme.Colors.primary
        }
        if isToday {
            return .blue
        }
        return Theme.Colors.label
    }
}
