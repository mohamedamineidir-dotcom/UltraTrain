import SwiftUI
import Charts

struct WeeklyNutritionChart: View {
    let entries: [FoodLogEntry]
    let dailyTarget: Int

    private var dailyCalories: [(date: Date, calories: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)
        var result: [(date: Date, calories: Int)] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(
                byAdding: .day, value: -dayOffset, to: today
            ) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let dayEntries = entries.filter {
                calendar.startOfDay(for: $0.date) == dayStart
            }
            let totalCalories = dayEntries
                .compactMap(\.caloriesEstimate)
                .reduce(0, +)
            result.append((date: dayStart, calories: totalCalories))
        }
        return result
    }

    private var averageAdherence: Int {
        let daysWithTarget = dailyCalories.filter { $0.calories > 0 }
        guard !daysWithTarget.isEmpty, dailyTarget > 0 else { return 0 }
        let totalAdherence = daysWithTarget.reduce(0.0) { sum, day in
            sum + min(Double(day.calories) / Double(dailyTarget), 1.0)
        }
        return Int((totalAdherence / Double(daysWithTarget.count)) * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("Weekly Overview", systemImage: "chart.bar.fill")
                .font(.headline)

            chartView

            HStack {
                Spacer()
                Text("Avg. adherence: \(averageAdherence)%")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .cardStyle()
        .accessibilityIdentifier("nutrition.weeklyChart")
    }

    private var chartView: some View {
        Chart {
            ForEach(dailyCalories, id: \.date) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Calories", item.calories)
                )
                .foregroundStyle(
                    item.calories >= dailyTarget
                        ? Theme.Colors.success.gradient
                        : Theme.Colors.primary.gradient
                )
                .cornerRadius(4)
            }

            if dailyTarget > 0 {
                RuleMark(y: .value("Target", dailyTarget))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .foregroundStyle(Theme.Colors.warning)
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Target")
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.warning)
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 180)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weekly calorie chart")
        .accessibilityValue(
            "Average adherence \(averageAdherence) percent over the past 7 days"
        )
    }
}
