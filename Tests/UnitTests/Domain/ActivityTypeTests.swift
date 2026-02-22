import Testing
import Foundation
@testable import UltraTrain

@Suite("ActivityType Tests")
struct ActivityTypeTests {

    // MARK: - Display Name

    @Test("Each activity type has a display name")
    func displayNames() {
        #expect(ActivityType.running.displayName == "Running")
        #expect(ActivityType.trailRunning.displayName == "Trail Running")
        #expect(ActivityType.cycling.displayName == "Cycling")
        #expect(ActivityType.swimming.displayName == "Swimming")
        #expect(ActivityType.hiking.displayName == "Hiking")
        #expect(ActivityType.strength.displayName == "Strength")
        #expect(ActivityType.yoga.displayName == "Yoga")
        #expect(ActivityType.other.displayName == "Other")
    }

    // MARK: - Icon Name

    @Test("Each activity type has an SF Symbol icon")
    func iconNames() {
        for activityType in ActivityType.allCases {
            #expect(!activityType.iconName.isEmpty)
        }
    }

    // MARK: - GPS Activity

    @Test("GPS activities are running, trail running, cycling, hiking")
    func gpsActivities() {
        #expect(ActivityType.running.isGPSActivity == true)
        #expect(ActivityType.trailRunning.isGPSActivity == true)
        #expect(ActivityType.cycling.isGPSActivity == true)
        #expect(ActivityType.hiking.isGPSActivity == true)
    }

    @Test("Non-GPS activities are swimming, strength, yoga, other")
    func nonGPSActivities() {
        #expect(ActivityType.swimming.isGPSActivity == false)
        #expect(ActivityType.strength.isGPSActivity == false)
        #expect(ActivityType.yoga.isGPSActivity == false)
        #expect(ActivityType.other.isGPSActivity == false)
    }

    // MARK: - Distance Based

    @Test("Distance-based activities include swimming but not strength")
    func distanceBased() {
        #expect(ActivityType.running.isDistanceBased == true)
        #expect(ActivityType.trailRunning.isDistanceBased == true)
        #expect(ActivityType.cycling.isDistanceBased == true)
        #expect(ActivityType.hiking.isDistanceBased == true)
        #expect(ActivityType.swimming.isDistanceBased == true)
        #expect(ActivityType.strength.isDistanceBased == false)
        #expect(ActivityType.yoga.isDistanceBased == false)
        #expect(ActivityType.other.isDistanceBased == false)
    }

    // MARK: - Raw Value Round-Trip

    @Test("Raw value round-trip preserves type")
    func rawValueRoundTrip() {
        for activityType in ActivityType.allCases {
            let restored = ActivityType(rawValue: activityType.rawValue)
            #expect(restored == activityType)
        }
    }

    @Test("Invalid raw value returns nil")
    func invalidRawValue() {
        #expect(ActivityType(rawValue: "invalid") == nil)
    }

    // MARK: - Codable

    @Test("Codable round-trip preserves type")
    func codableRoundTrip() throws {
        for activityType in ActivityType.allCases {
            let data = try JSONEncoder().encode(activityType)
            let decoded = try JSONDecoder().decode(ActivityType.self, from: data)
            #expect(decoded == activityType)
        }
    }
}
