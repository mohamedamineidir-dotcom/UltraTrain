import Foundation
import HealthKit
import Testing
@testable import UltraTrain

@Suite("HealthKitQueryHelper Tests")
struct HealthKitQueryHelperTests {

    // NOTE: HealthKit queries require an HKHealthStore that is only available on device.
    // We test the pure computation methods: activity type mapping, type set construction,
    // and elevation extraction logic.

    // MARK: - Activity Type Mapping

    @Test("mapActivityType maps running correctly")
    func mapRunning() {
        let result = HealthKitQueryHelper.mapActivityType(.running)
        #expect(result == .running)
    }

    @Test("mapActivityType maps cycling correctly")
    func mapCycling() {
        let result = HealthKitQueryHelper.mapActivityType(.cycling)
        #expect(result == .cycling)
    }

    @Test("mapActivityType maps swimming correctly")
    func mapSwimming() {
        let result = HealthKitQueryHelper.mapActivityType(.swimming)
        #expect(result == .swimming)
    }

    @Test("mapActivityType maps hiking correctly")
    func mapHiking() {
        let result = HealthKitQueryHelper.mapActivityType(.hiking)
        #expect(result == .hiking)
    }

    @Test("mapActivityType maps yoga correctly")
    func mapYoga() {
        let result = HealthKitQueryHelper.mapActivityType(.yoga)
        #expect(result == .yoga)
    }

    @Test("mapActivityType maps strength training correctly")
    func mapStrength() {
        let functional = HealthKitQueryHelper.mapActivityType(.functionalStrengthTraining)
        let traditional = HealthKitQueryHelper.mapActivityType(.traditionalStrengthTraining)
        #expect(functional == .strength)
        #expect(traditional == .strength)
    }

    @Test("mapActivityType maps unknown type to other")
    func mapUnknown() {
        let result = HealthKitQueryHelper.mapActivityType(.dance)
        #expect(result == .other)
    }

    // MARK: - Reverse Mapping (hkActivityTypes)

    @Test("hkActivityTypes maps running to HKWorkoutActivityType.running")
    func reverseMapRunning() {
        let result = HealthKitQueryHelper.hkActivityTypes(for: [.running])
        #expect(result.contains(.running))
    }

    @Test("hkActivityTypes maps trailRunning to HKWorkoutActivityType.running")
    func reverseMapTrailRunning() {
        let result = HealthKitQueryHelper.hkActivityTypes(for: [.trailRunning])
        #expect(result.contains(.running))
    }

    @Test("hkActivityTypes maps strength to both strength types")
    func reverseMapStrength() {
        let result = HealthKitQueryHelper.hkActivityTypes(for: [.strength])
        #expect(result.contains(.functionalStrengthTraining))
        #expect(result.contains(.traditionalStrengthTraining))
    }

    @Test("hkActivityTypes maps other to empty array")
    func reverseMapOther() {
        let result = HealthKitQueryHelper.hkActivityTypes(for: [.other])
        #expect(result.isEmpty)
    }

    @Test("hkActivityTypes handles multiple activity types")
    func reverseMapMultiple() {
        let result = HealthKitQueryHelper.hkActivityTypes(for: [.running, .cycling, .swimming])
        #expect(result.contains(.running))
        #expect(result.contains(.cycling))
        #expect(result.contains(.swimming))
    }

    // MARK: - Read/Write Types

    @Test("readTypes includes heart rate")
    func readTypesIncludesHeartRate() {
        let types = HealthKitQueryHelper.readTypes()
        #expect(types.contains(HKQuantityType(.heartRate)))
    }

    @Test("readTypes includes body mass")
    func readTypesIncludesBodyMass() {
        let types = HealthKitQueryHelper.readTypes()
        #expect(types.contains(HKQuantityType(.bodyMass)))
    }

    @Test("readTypes includes sleep analysis")
    func readTypesIncludesSleep() {
        let types = HealthKitQueryHelper.readTypes()
        #expect(types.contains(HKCategoryType(.sleepAnalysis)))
    }

    @Test("writeTypes includes workout type")
    func writeTypesIncludesWorkout() {
        let types = HealthKitQueryHelper.writeTypes()
        #expect(types.contains(HKWorkoutType.workoutType()))
    }

    @Test("writeTypes includes distance walking running")
    func writeTypesIncludesDistance() {
        let types = HealthKitQueryHelper.writeTypes()
        #expect(types.contains(HKQuantityType(.distanceWalkingRunning)))
    }
}
