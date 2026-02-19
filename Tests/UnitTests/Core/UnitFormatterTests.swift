import Testing
@testable import UltraTrain

@Suite("UnitFormatter")
struct UnitFormatterTests {

    // MARK: - Distance

    @Test func formatDistanceMetric() {
        #expect(UnitFormatter.formatDistance(12.3, unit: .metric) == "12.3 km")
    }

    @Test func formatDistanceImperial() {
        let result = UnitFormatter.formatDistance(12.3, unit: .imperial)
        #expect(result == "7.6 mi")
    }

    @Test func formatDistanceZero() {
        #expect(UnitFormatter.formatDistance(0, unit: .metric) == "0.0 km")
        #expect(UnitFormatter.formatDistance(0, unit: .imperial) == "0.0 mi")
    }

    @Test func formatDistanceCustomDecimals() {
        #expect(UnitFormatter.formatDistance(42.195, unit: .metric, decimals: 0) == "42 km")
        #expect(UnitFormatter.formatDistance(42.195, unit: .imperial, decimals: 2) == "26.22 mi")
    }

    // MARK: - Elevation

    @Test func formatElevationMetric() {
        #expect(UnitFormatter.formatElevation(500, unit: .metric) == "500 m")
    }

    @Test func formatElevationImperial() {
        #expect(UnitFormatter.formatElevation(500, unit: .imperial) == "1640 ft")
    }

    @Test func formatElevationZero() {
        #expect(UnitFormatter.formatElevation(0, unit: .metric) == "0 m")
        #expect(UnitFormatter.formatElevation(0, unit: .imperial) == "0 ft")
    }

    // MARK: - Pace

    @Test func formatPaceMetric() {
        // 360 sec/km = 6:00 /km
        #expect(UnitFormatter.formatPace(360, unit: .metric) == "6:00")
    }

    @Test func formatPaceImperial() {
        // 360 sec/km × 1.60934 = ~579.36 sec/mi = 9:39
        let result = UnitFormatter.formatPace(360, unit: .imperial)
        #expect(result == "9:39")
    }

    @Test func formatPaceInvalid() {
        #expect(UnitFormatter.formatPace(0, unit: .metric) == "--:--")
        #expect(UnitFormatter.formatPace(-10, unit: .imperial) == "--:--")
        #expect(UnitFormatter.formatPace(.infinity, unit: .metric) == "--:--")
    }

    // MARK: - Weight

    @Test func formatWeightMetric() {
        #expect(UnitFormatter.formatWeight(70, unit: .metric) == "70.0 kg")
    }

    @Test func formatWeightImperial() {
        #expect(UnitFormatter.formatWeight(70, unit: .imperial) == "154.3 lb")
    }

    // MARK: - Height

    @Test func formatHeightMetric() {
        #expect(UnitFormatter.formatHeight(175, unit: .metric) == "175 cm")
    }

    @Test func formatHeightImperial() {
        // 175 cm / 2.54 = 68.9 inches, rounded = 69 inches = 5 feet 9 inches → "5'9\""
        let result = UnitFormatter.formatHeight(175, unit: .imperial)
        #expect(result == "5'9\"")
    }

    // MARK: - Labels

    @Test func distanceLabels() {
        #expect(UnitFormatter.distanceLabel(.metric) == "km")
        #expect(UnitFormatter.distanceLabel(.imperial) == "mi")
    }

    @Test func elevationLabels() {
        #expect(UnitFormatter.elevationLabel(.metric) == "m D+")
        #expect(UnitFormatter.elevationLabel(.imperial) == "ft D+")
        #expect(UnitFormatter.elevationShortLabel(.metric) == "m")
        #expect(UnitFormatter.elevationShortLabel(.imperial) == "ft")
    }

    @Test func paceLabels() {
        #expect(UnitFormatter.paceLabel(.metric) == "/km")
        #expect(UnitFormatter.paceLabel(.imperial) == "/mi")
    }

    @Test func weightLabels() {
        #expect(UnitFormatter.weightLabel(.metric) == "kg")
        #expect(UnitFormatter.weightLabel(.imperial) == "lb")
    }

    // MARK: - Value Conversion

    @Test func distanceValueConversion() {
        let miles = UnitFormatter.distanceValue(10, unit: .imperial)
        #expect(abs(miles - 6.21371) < 0.001)
        #expect(UnitFormatter.distanceValue(10, unit: .metric) == 10)
    }

    @Test func elevationValueConversion() {
        let feet = UnitFormatter.elevationValue(1000, unit: .imperial)
        #expect(abs(feet - 3280.84) < 0.1)
        #expect(UnitFormatter.elevationValue(1000, unit: .metric) == 1000)
    }

    @Test func weightValueConversion() {
        let lbs = UnitFormatter.weightValue(80, unit: .imperial)
        #expect(abs(lbs - 176.37) < 0.1)
        #expect(UnitFormatter.weightValue(80, unit: .metric) == 80)
    }

    @Test func paceValueConversion() {
        // 300 sec/km × 1.60934 ≈ 482.8 sec/mi
        let secPerMile = UnitFormatter.paceValue(300, unit: .imperial)
        #expect(abs(secPerMile - 482.8) < 0.1)
        #expect(UnitFormatter.paceValue(300, unit: .metric) == 300)
    }

    // MARK: - Round-Trip Conversion

    @Test func distanceRoundTrip() {
        let original = 42.195
        let miles = UnitFormatter.distanceValue(original, unit: .imperial)
        let backToKm = UnitFormatter.distanceToKm(miles, unit: .imperial)
        #expect(abs(backToKm - original) < 0.001)
    }

    @Test func elevationRoundTrip() {
        let original = 3500.0
        let feet = UnitFormatter.elevationValue(original, unit: .imperial)
        let backToM = UnitFormatter.elevationToMeters(feet, unit: .imperial)
        #expect(abs(backToM - original) < 0.01)
    }

    @Test func weightRoundTrip() {
        let original = 72.5
        let lbs = UnitFormatter.weightValue(original, unit: .imperial)
        let backToKg = UnitFormatter.weightToKg(lbs, unit: .imperial)
        #expect(abs(backToKg - original) < 0.01)
    }

    // MARK: - Metric Pass-Through

    @Test func metricReverseConversionsAreIdentity() {
        #expect(UnitFormatter.distanceToKm(10, unit: .metric) == 10)
        #expect(UnitFormatter.elevationToMeters(500, unit: .metric) == 500)
        #expect(UnitFormatter.weightToKg(70, unit: .metric) == 70)
    }
}
