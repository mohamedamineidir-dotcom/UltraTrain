import SwiftUI

struct CalendarDayCell: View {
    let date: Date
    let phase: TrainingPhase?
    let race: Race?
    let sessionCount: Int
    let isSelected: Bool
    let isToday: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(.callout, design: .rounded))
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(foregroundColor)

            dotIndicator
        }
        .frame(maxWidth: .infinity, minHeight: 40)
        .background(backgroundView)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var parts: [String] = []
        parts.append(date.formatted(.dateTime.month(.wide).day()))
        if isToday { parts.append("Today") }
        if let phase { parts.append(phase.displayName) }
        if let race { parts.append("\(race.priority.displayName) race: \(race.name)") }
        if sessionCount > 0 { parts.append("\(sessionCount) session\(sessionCount > 1 ? "s" : "")") }
        return parts.joined(separator: ", ")
    }

    @ViewBuilder
    private var dotIndicator: some View {
        if let race {
            Circle()
                .fill(race.priority.badgeColor)
                .frame(width: 6, height: 6)
        } else if sessionCount > 0 {
            Circle()
                .fill(Theme.Colors.primary)
                .frame(width: 4, height: 4)
        } else {
            Circle()
                .fill(.clear)
                .frame(width: 4, height: 4)
        }
    }

    private var backgroundView: some View {
        ZStack {
            if let phase {
                Circle()
                    .fill(phase.color.opacity(0.15))
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
