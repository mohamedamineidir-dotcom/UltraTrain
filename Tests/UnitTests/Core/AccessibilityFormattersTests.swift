import Foundation
import Testing
@testable import UltraTrain

@Suite("AccessibilityFormatters Tests")
struct AccessibilityFormattersTests {

    // MARK: - Pace

    @Test("Pace metric formats correctly")
    func paceMetric() {
        let result = AccessibilityFormatters.pace("5:30", unit: .metric)
        #expect(result == "5 minutes 30 seconds per kilometer")
    }

    @Test("Pace imperial formats correctly")
    func paceImperial() {
        let result = AccessibilityFormatters.pace("8:30", unit: .imperial)
        #expect(result == "8 minutes 30 seconds per mile")
    }

    @Test("Pace with zero seconds omits seconds")
    func paceZeroSeconds() {
        let result = AccessibilityFormatters.pace("6:00", unit: .metric)
        #expect(result == "6 minutes per kilometer")
    }

    @Test("Pace with 1 minute uses singular")
    func paceSingularMinute() {
        let result = AccessibilityFormatters.pace("1:30", unit: .metric)
        #expect(result == "1 minute 30 seconds per kilometer")
    }

    @Test("Pace with 1 second uses singular")
    func paceSingularSecond() {
        let result = AccessibilityFormatters.pace("5:01", unit: .metric)
        #expect(result == "5 minutes 1 second per kilometer")
    }

    @Test("Pace with invalid string returns original")
    func paceInvalid() {
        let result = AccessibilityFormatters.pace("--:--", unit: .metric)
        #expect(result == "--:--")
    }

    // MARK: - Duration

    @Test("Duration with hours and minutes")
    func durationHoursAndMinutes() {
        let result = AccessibilityFormatters.duration(3661)
        #expect(result == "1 hour 1 minute")
    }

    @Test("Duration minutes only")
    func durationMinutesOnly() {
        let result = AccessibilityFormatters.duration(1800)
        #expect(result == "30 minutes")
    }

    @Test("Duration zero seconds")
    func durationZero() {
        let result = AccessibilityFormatters.duration(0)
        #expect(result == "0 minutes")
    }

    @Test("Duration plural hours and minutes")
    func durationPlural() {
        let result = AccessibilityFormatters.duration(7500)
        #expect(result == "2 hours 5 minutes")
    }

    @Test("Duration exact hours")
    func durationExactHours() {
        let result = AccessibilityFormatters.duration(7200)
        #expect(result == "2 hours")
    }

    // MARK: - Elevation

    @Test("Elevation metric formats correctly")
    func elevationMetric() {
        let result = AccessibilityFormatters.elevation(450, unit: .metric)
        #expect(result == "450 meters elevation gain")
    }

    @Test("Elevation imperial formats correctly")
    func elevationImperial() {
        let result = AccessibilityFormatters.elevation(450, unit: .imperial)
        #expect(result == "1476 feet elevation gain")
    }

    // MARK: - Distance

    @Test("Distance metric formats correctly")
    func distanceMetric() {
        let result = AccessibilityFormatters.distance(21.5, unit: .metric)
        #expect(result == "21.5 kilometers")
    }

    @Test("Distance imperial formats correctly")
    func distanceImperial() {
        let result = AccessibilityFormatters.distance(21.5, unit: .imperial)
        #expect(result == "13.4 miles")
    }

    @Test("Distance whole number omits decimal")
    func distanceWholeNumber() {
        let result = AccessibilityFormatters.distance(10.0, unit: .metric)
        #expect(result == "10 kilometers")
    }
}
