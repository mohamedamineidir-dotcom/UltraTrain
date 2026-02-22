import SwiftUI

struct TrainingCalendarGridView: View {
    let displayedMonth: Date
    let statusForDate: (Date) -> TrainingCalendarDayStatus
    let phaseForDate: (Date) -> TrainingPhase?
    @Binding var selectedDate: Date?
    let onNavigate: (Int) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            monthHeader
            weekdayHeader
            dayGrid
        }
        .gesture(swipeGesture)
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button { onNavigate(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.body.bold())
                    .foregroundStyle(Theme.Colors.primary)
            }
            .accessibilityLabel("Previous month")
            .accessibilityHint("Double-tap to navigate to the previous month")

            Spacer()

            Text(monthYearString)
                .font(.title3.bold())

            Spacer()

            Button { onNavigate(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.body.bold())
                    .foregroundStyle(Theme.Colors.primary)
            }
            .accessibilityLabel("Next month")
            .accessibilityHint("Double-tap to navigate to the next month")
        }
        .padding(.horizontal, Theme.Spacing.xs)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2.bold())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Day Grid

    private var dayGrid: some View {
        let days = computeDaysInMonth()
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    Button {
                        selectedDate = day
                    } label: {
                        TrainingCalendarDayCell(
                            date: day,
                            status: statusForDate(day),
                            phase: phaseForDate(day),
                            isSelected: selectedDate?.isSameDay(as: day) == true,
                            isToday: day.isSameDay(as: .now)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(dayCellAccessibilityLabel(for: day))
                    .accessibilityHint("Double-tap to view day details")
                } else {
                    Color.clear
                        .frame(minHeight: 40)
                }
            }
        }
    }

    // MARK: - Helpers

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private func computeDaysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let firstDay = displayedMonth.startOfMonth
        let leadingBlanks = firstDay.weekdayIndex

        guard let range = calendar.range(of: .day, in: .month, for: firstDay) else {
            return []
        }

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in range {
            if let dayDate = calendar.date(bySetting: .day, value: day, of: firstDay) {
                days.append(dayDate)
            }
        }
        return days
    }

    private func dayCellAccessibilityLabel(for date: Date) -> String {
        let dayString = date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        let status = statusForDate(date)
        let statusDescription: String
        switch status {
        case .completed:
            statusDescription = "all sessions completed"
        case .partial:
            statusDescription = "partially completed"
        case .planned:
            statusDescription = "sessions planned"
        case .ranWithoutPlan:
            statusDescription = "unplanned run completed"
        case .rest:
            statusDescription = "rest day"
        case .noActivity:
            statusDescription = "no activity"
        }
        var label = "\(dayString), \(statusDescription)"
        if date.isSameDay(as: .now) {
            label += ", today"
        }
        if let phase = phaseForDate(date) {
            label += ", \(phase.displayName) phase"
        }
        return label
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                if value.translation.width < -50 {
                    onNavigate(1)
                } else if value.translation.width > 50 {
                    onNavigate(-1)
                }
            }
    }
}
