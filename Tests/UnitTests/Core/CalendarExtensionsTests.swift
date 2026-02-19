import Foundation
import Testing
@testable import UltraTrain

@Suite("Calendar Extensions Tests")
struct CalendarExtensionsTests {

    @Test("startOfMonth returns first day of month")
    func startOfMonth() {
        let date = makeDate(year: 2026, month: 3, day: 15)
        let result = date.startOfMonth
        let components = Calendar.current.dateComponents([.year, .month, .day], from: result)
        #expect(components.year == 2026)
        #expect(components.month == 3)
        #expect(components.day == 1)
    }

    @Test("endOfMonth returns last day of month")
    func endOfMonth() {
        let date = makeDate(year: 2026, month: 2, day: 10)
        let result = date.endOfMonth
        let day = Calendar.current.component(.day, from: result)
        #expect(day == 28)
    }

    @Test("endOfMonth handles leap year")
    func endOfMonthLeapYear() {
        let date = makeDate(year: 2028, month: 2, day: 5)
        let result = date.endOfMonth
        let day = Calendar.current.component(.day, from: result)
        #expect(day == 29)
    }

    @Test("adding months navigates forward")
    func addingMonthsForward() {
        let date = makeDate(year: 2026, month: 1, day: 15)
        let result = date.adding(months: 3)
        let components = Calendar.current.dateComponents([.year, .month], from: result)
        #expect(components.year == 2026)
        #expect(components.month == 4)
    }

    @Test("adding months navigates backward")
    func addingMonthsBackward() {
        let date = makeDate(year: 2026, month: 3, day: 10)
        let result = date.adding(months: -2)
        let components = Calendar.current.dateComponents([.year, .month], from: result)
        #expect(components.year == 2026)
        #expect(components.month == 1)
    }

    @Test("isSameDay returns true for same day")
    func isSameDayTrue() {
        let date1 = makeDate(year: 2026, month: 5, day: 20, hour: 8)
        let date2 = makeDate(year: 2026, month: 5, day: 20, hour: 22)
        #expect(date1.isSameDay(as: date2))
    }

    @Test("isSameDay returns false for different days")
    func isSameDayFalse() {
        let date1 = makeDate(year: 2026, month: 5, day: 20)
        let date2 = makeDate(year: 2026, month: 5, day: 21)
        #expect(!date1.isSameDay(as: date2))
    }

    @Test("weekdayIndex returns 0-based index")
    func weekdayIndex() {
        // January 4, 2026 is a Sunday
        let sunday = makeDate(year: 2026, month: 1, day: 4)
        #expect(sunday.weekdayIndex == 0)

        // January 5, 2026 is a Monday
        let monday = makeDate(year: 2026, month: 1, day: 5)
        #expect(monday.weekdayIndex == 1)
    }

    // MARK: - Helpers

    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return Calendar.current.date(from: components)!
    }
}
