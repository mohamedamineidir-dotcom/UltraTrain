import SwiftUI

struct CalendarMonthGridView: View {
    let displayedMonth: Date
    let phaseForDate: (Date) -> TrainingPhase?
    let raceForDate: (Date) -> Race?
    let sessionsForDate: (Date) -> [TrainingSession]
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
            .accessibilityHint("Navigates to the previous month")

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
            .accessibilityHint("Navigates to the next month")
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
                        CalendarDayCell(
                            date: day,
                            phase: phaseForDate(day),
                            race: raceForDate(day),
                            sessionCount: sessionsForDate(day).count,
                            isSelected: selectedDate?.isSameDay(as: day) == true,
                            isToday: day.isSameDay(as: .now)
                        )
                    }
                    .buttonStyle(.plain)
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
