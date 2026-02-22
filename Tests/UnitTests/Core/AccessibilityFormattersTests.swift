import Foundation
import Testing
@testable import UltraTrain

@Suite("AccessibilityFormatters Tests")
struct AccessibilityFormattersTests {

    // MARK: - Pace

    @Test("Pace metric formats correctly")
    func paceMetric() {
        let result = AccessibilityFormatters.pace("5:30", unit: .metric)
        #expect(result == "5 min 30 sec per kilometer")
    }

    @Test("Pace imperial formats correctly")
    func paceImperial() {
        let result = AccessibilityFormatters.pace("8:30", unit: .imperial)
        #expect(result == "8 min 30 sec per mile")
    }

    @Test("Pace with zero seconds omits seconds")
    func paceZeroSeconds() {
        let result = AccessibilityFormatters.pace("6:00", unit: .metric)
        #expect(result == "6 min per kilometer")
    }

    @Test("Pace with 1 minute uses same abbreviation")
    func paceSingularMinute() {
        let result = AccessibilityFormatters.pace("1:30", unit: .metric)
        #expect(result == "1 min 30 sec per kilometer")
    }

    @Test("Pace with 1 second uses same abbreviation")
    func paceSingularSecond() {
        let result = AccessibilityFormatters.pace("5:01", unit: .metric)
        #expect(result == "5 min 1 sec per kilometer")
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
        #expect(result == "1 hr 1 min")
    }

    @Test("Duration minutes only")
    func durationMinutesOnly() {
        let result = AccessibilityFormatters.duration(1800)
        #expect(result == "30 min")
    }

    @Test("Duration zero seconds")
    func durationZero() {
        let result = AccessibilityFormatters.duration(0)
        #expect(result == "0 min")
    }

    @Test("Duration plural hours and minutes")
    func durationPlural() {
        let result = AccessibilityFormatters.duration(7500)
        #expect(result == "2 hr 5 min")
    }

    @Test("Duration exact hours")
    func durationExactHours() {
        let result = AccessibilityFormatters.duration(7200)
        #expect(result == "2 hr")
    }

    // MARK: - Elevation

    @Test("Elevation metric formats correctly")
    func elevationMetric() {
        let result = AccessibilityFormatters.elevation(450, unit: .metric)
        #expect(result == "450 m D+")
    }

    @Test("Elevation imperial formats correctly")
    func elevationImperial() {
        let result = AccessibilityFormatters.elevation(450, unit: .imperial)
        #expect(result == "1476 ft D+")
    }

    // MARK: - Distance

    @Test("Distance metric formats correctly")
    func distanceMetric() {
        let result = AccessibilityFormatters.distance(21.5, unit: .metric)
        #expect(result == "21.5 km")
    }

    @Test("Distance imperial formats correctly")
    func distanceImperial() {
        let result = AccessibilityFormatters.distance(21.5, unit: .imperial)
        #expect(result == "13.4 mi")
    }

    @Test("Distance whole number omits decimal")
    func distanceWholeNumber() {
        let result = AccessibilityFormatters.distance(10.0, unit: .metric)
        #expect(result == "10 km")
    }
}
