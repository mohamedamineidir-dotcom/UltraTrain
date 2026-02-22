import Foundation
import Testing
@testable import UltraTrain

@Suite("WatchHRZoneCalculator Tests")
struct WatchHRZoneCalculatorTests {

    // Using standard values: maxHR = 190, restingHR = 50
    // HR Reserve = 140
    // Zone boundaries (Karvonen):
    //   Zone 1: intensity < 0.6 → HR < 50 + 0.6 * 140 = 134
    //   Zone 2: 0.6 <= intensity < 0.7 → 134 <= HR < 148
    //   Zone 3: 0.7 <= intensity < 0.8 → 148 <= HR < 162
    //   Zone 4: 0.8 <= intensity < 0.9 → 162 <= HR < 176
    //   Zone 5: intensity >= 0.9 → HR >= 176

    private let maxHR = 190
    private let restingHR = 50

    // MARK: - Zone Detection

    @Test("Zone 1 at low heart rate")
    func zone1_atLowHeartRate() {
        let zone = WatchHRZoneCalculator.zone(heartRate: 100, maxHR: maxHR, restingHR: restingHR)
        #expect(zone == 1)
    }

    @Test("Zone 2 at moderate heart rate")
    func zone2_atModerateHeartRate() {
        // intensity = (140 - 50) / 140 = 0.643 → zone 2
        let zone = WatchHRZoneCalculator.zone(heartRate: 140, maxHR: maxHR, restingHR: restingHR)
        #expect(zone == 2)
    }

    @Test("Zone 3 at tempo heart rate")
    func zone3_atTempoHeartRate() {
        // intensity = (155 - 50) / 140 = 0.75 → zone 3
        let zone = WatchHRZoneCalculator.zone(heartRate: 155, maxHR: maxHR, restingHR: restingHR)
        #expect(zone == 3)
    }

    @Test("Zone 4 at threshold heart rate")
    func zone4_atThresholdHeartRate() {
        // intensity = (165 - 50) / 140 = 0.821 → zone 4
        let zone = WatchHRZoneCalculator.zone(heartRate: 165, maxHR: maxHR, restingHR: restingHR)
        #expect(zone == 4)
    }

    @Test("Zone 5 at max heart rate")
    func zone5_atMaxHeartRate() {
        // intensity = (185 - 50) / 140 = 0.964 → zone 5
        let zone = WatchHRZoneCalculator.zone(heartRate: 185, maxHR: maxHR, restingHR: restingHR)
        #expect(zone == 5)
    }

    // MARK: - Zone Names

    @Test("zoneName returns correct names for all zones")
    func zoneName_returnsCorrectNames() {
        #expect(WatchHRZoneCalculator.zoneName(1) == "Recovery")
        #expect(WatchHRZoneCalculator.zoneName(2) == "Aerobic")
        #expect(WatchHRZoneCalculator.zoneName(3) == "Tempo")
        #expect(WatchHRZoneCalculator.zoneName(4) == "Threshold")
        #expect(WatchHRZoneCalculator.zoneName(5) == "VO2max")
    }

    @Test("zoneName for unknown zone returns Unknown")
    func zoneName_unknownZone_returnsUnknown() {
        #expect(WatchHRZoneCalculator.zoneName(0) == "Unknown")
        #expect(WatchHRZoneCalculator.zoneName(6) == "Unknown")
    }

    // MARK: - Zone Colors

    @Test("zoneColorName returns correct colors for all zones")
    func zoneColorName_returnsCorrectColors() {
        #expect(WatchHRZoneCalculator.zoneColorName(1) == "green")
        #expect(WatchHRZoneCalculator.zoneColorName(2) == "blue")
        #expect(WatchHRZoneCalculator.zoneColorName(3) == "yellow")
        #expect(WatchHRZoneCalculator.zoneColorName(4) == "orange")
        #expect(WatchHRZoneCalculator.zoneColorName(5) == "red")
    }

    @Test("zoneColorName for unknown zone returns gray")
    func zoneColorName_unknownZone_returnsGray() {
        #expect(WatchHRZoneCalculator.zoneColorName(0) == "gray")
        #expect(WatchHRZoneCalculator.zoneColorName(6) == "gray")
    }

    // MARK: - Edge Cases

    @Test("Heart rate below resting returns zone 1")
    func zone_heartRateBelowResting_returnsZone1() {
        let zone = WatchHRZoneCalculator.zone(heartRate: 40, maxHR: maxHR, restingHR: restingHR)
        #expect(zone == 1)
    }

    @Test("Heart rate above max returns zone 5")
    func zone_heartRateAboveMax_returnsZone5() {
        let zone = WatchHRZoneCalculator.zone(heartRate: 200, maxHR: maxHR, restingHR: restingHR)
        #expect(zone == 5)
    }

    @Test("Heart rate of zero returns zone 1")
    func zone_heartRateZero_returnsZone1() {
        let zone = WatchHRZoneCalculator.zone(heartRate: 0, maxHR: maxHR, restingHR: restingHR)
        #expect(zone == 1)
    }

    @Test("Equal max and resting HR returns zone 1")
    func zone_equalMaxAndResting_returnsZone1() {
        let zone = WatchHRZoneCalculator.zone(heartRate: 80, maxHR: 80, restingHR: 80)
        #expect(zone == 1)
    }
}
