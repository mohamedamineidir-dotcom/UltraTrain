import SwiftUI

struct TrainingCalendarHeatmapView: View {
    let dayIntensities: [TrainingCalendarHeatmapCalculator.DayIntensity]
    @State private var selectedDay: TrainingCalendarHeatmapCalculator.DayIntensity?

    private let cellSize: CGFloat = 14
    private let cellSpacing: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Training Activity")
                .font(.headline)

            if dayIntensities.isEmpty {
                Text("No activity data yet")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                calendarGrid
                legendRow
            }
        }
        .overlay {
            if let selectedDay {
                HeatmapDayDetailPopup(day: selectedDay) {
                    self.selectedDay = nil
                }
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    dayLabelsColumn
                    weekColumnsWithMonthLabels(scrollProxy: scrollProxy)
                }
            }
            .onAppear {
                if let lastWeekId = weekGroups.last?.id {
                    scrollProxy.scrollTo(lastWeekId, anchor: .trailing)
                }
            }
        }
    }

    // MARK: - Day Labels

    private var dayLabelsColumn: some View {
        VStack(spacing: cellSpacing) {
            // Spacer for month label row
            Text("")
                .font(.caption2)
                .frame(height: 12)

            ForEach(0..<7, id: \.self) { dayIndex in
                if dayIndex == 0 || dayIndex == 2 || dayIndex == 4 {
                    Text(dayAbbreviation(for: dayIndex))
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .frame(width: 16, height: cellSize)
                } else {
                    Color.clear
                        .frame(width: 16, height: cellSize)
                }
            }
        }
    }

    // MARK: - Week Columns

    private func weekColumnsWithMonthLabels(
        scrollProxy: ScrollViewProxy
    ) -> some View {
        HStack(alignment: .top, spacing: cellSpacing) {
            ForEach(weekGroups) { weekGroup in
                VStack(spacing: cellSpacing) {
                    monthLabel(for: weekGroup)
                        .frame(height: 12)

                    ForEach(weekGroup.days, id: \.id) { day in
                        dayCellView(for: day)
                    }

                    // Fill remaining cells for incomplete weeks
                    if weekGroup.days.count < 7 {
                        ForEach(0..<(7 - weekGroup.days.count), id: \.self) { _ in
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
                .id(weekGroup.id)
            }
        }
    }

    // MARK: - Day Cell

    private func dayCellView(
        for day: TrainingCalendarHeatmapCalculator.DayIntensity
    ) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(colorForIntensity(day.intensity))
            .frame(width: cellSize, height: cellSize)
            .onTapGesture {
                if day.runCount > 0 {
                    selectedDay = day
                }
            }
            .accessibilityLabel(dayCellAccessibilityLabel(for: day))
    }

    // MARK: - Month Label

    @ViewBuilder
    private func monthLabel(for weekGroup: WeekGroup) -> some View {
        if weekGroup.isFirstWeekOfMonth {
            Text(weekGroup.monthAbbreviation)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        } else {
            Text("")
                .font(.caption2)
        }
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text("Less")
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            ForEach(
                TrainingCalendarHeatmapCalculator.IntensityLevel.allCases,
                id: \.rawValue
            ) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(colorForIntensity(level))
                    .frame(width: 10, height: 10)
            }

            Text("More")
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Color Mapping

    private func colorForIntensity(
        _ intensity: TrainingCalendarHeatmapCalculator.IntensityLevel
    ) -> Color {
        switch intensity {
        case .rest:
            return Color.gray.opacity(0.15)
        case .easy:
            return Theme.Colors.success.opacity(0.3)
        case .moderate:
            return Theme.Colors.success.opacity(0.55)
        case .hard:
            return Theme.Colors.success.opacity(0.8)
        case .veryHard:
            return Theme.Colors.success
        }
    }

    // MARK: - Week Grouping

    private struct WeekGroup: Identifiable {
        let id: Int
        let days: [TrainingCalendarHeatmapCalculator.DayIntensity]
        let isFirstWeekOfMonth: Bool
        let monthAbbreviation: String
    }

    private var weekGroups: [WeekGroup] {
        let calendar = Calendar.current
        var groups: [WeekGroup] = []
        var currentWeekDays: [TrainingCalendarHeatmapCalculator.DayIntensity] = []
        var previousMonth: Int?
        var weekIndex = 0

        for day in dayIntensities {
            let weekday = calendar.component(.weekday, from: day.date)
            // Convert to Monday-based: Mon=0, Tue=1, ..., Sun=6
            let mondayBased = (weekday + 5) % 7

            if mondayBased == 0, !currentWeekDays.isEmpty {
                let firstDay = currentWeekDays[0].date
                let month = calendar.component(.month, from: firstDay)
                let isNewMonth = previousMonth == nil || month != previousMonth
                let abbr = firstDay.formatted(.dateTime.month(.abbreviated))

                groups.append(WeekGroup(
                    id: weekIndex,
                    days: currentWeekDays,
                    isFirstWeekOfMonth: isNewMonth,
                    monthAbbreviation: abbr
                ))

                previousMonth = month
                weekIndex += 1
                currentWeekDays = []
            }

            currentWeekDays.append(day)
        }

        // Flush remaining days
        if !currentWeekDays.isEmpty {
            let firstDay = currentWeekDays[0].date
            let month = Calendar.current.component(.month, from: firstDay)
            let isNewMonth = previousMonth == nil || month != previousMonth
            let abbr = firstDay.formatted(.dateTime.month(.abbreviated))

            groups.append(WeekGroup(
                id: weekIndex,
                days: currentWeekDays,
                isFirstWeekOfMonth: isNewMonth,
                monthAbbreviation: abbr
            ))
        }

        return groups
    }

    // MARK: - Helpers

    private func dayAbbreviation(for mondayBasedIndex: Int) -> String {
        switch mondayBasedIndex {
        case 0: return "M"
        case 2: return "W"
        case 4: return "F"
        default: return ""
        }
    }

    private func dayCellAccessibilityLabel(
        for day: TrainingCalendarHeatmapCalculator.DayIntensity
    ) -> String {
        let dateStr = day.date.formatted(.dateTime.month().day())
        if day.runCount == 0 {
            return "\(dateStr): rest day"
        }
        return "\(dateStr): \(day.runCount) run\(day.runCount == 1 ? "" : "s"), \(String(format: "%.1f", day.totalDistanceKm)) km"
    }
}
