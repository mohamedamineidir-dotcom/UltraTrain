import Foundation
import Testing
@testable import UltraTrain

@Suite("GearItem Model Tests")
struct GearItemTests {

    private func makeGear(
        totalDistanceKm: Double = 0,
        maxDistanceKm: Double = 800,
        isRetired: Bool = false
    ) -> GearItem {
        GearItem(
            id: UUID(),
            name: "Speedcross 6",
            brand: "Salomon",
            type: .trailShoes,
            purchaseDate: Date.now,
            maxDistanceKm: maxDistanceKm,
            totalDistanceKm: totalDistanceKm,
            totalDuration: 0,
            isRetired: isRetired,
            notes: nil
        )
    }

    // MARK: - Usage Percentage

    @Test("Usage percentage is zero when no distance logged")
    func usagePercentageZero() {
        let gear = makeGear(totalDistanceKm: 0, maxDistanceKm: 800)
        #expect(gear.usagePercentage == 0)
    }

    @Test("Usage percentage is 50% at half distance")
    func usagePercentageHalf() {
        let gear = makeGear(totalDistanceKm: 400, maxDistanceKm: 800)
        #expect(gear.usagePercentage == 0.5)
    }

    @Test("Usage percentage caps at 1.0 when over max")
    func usagePercentageCapped() {
        let gear = makeGear(totalDistanceKm: 1000, maxDistanceKm: 800)
        #expect(gear.usagePercentage == 1.0)
    }

    @Test("Usage percentage is zero when maxDistanceKm is zero")
    func usagePercentageZeroMax() {
        let gear = makeGear(totalDistanceKm: 100, maxDistanceKm: 0)
        #expect(gear.usagePercentage == 0)
    }

    // MARK: - Needs Replacement

    @Test("Needs replacement when total equals max")
    func needsReplacementAtMax() {
        let gear = makeGear(totalDistanceKm: 800, maxDistanceKm: 800)
        #expect(gear.needsReplacement == true)
    }

    @Test("Needs replacement when total exceeds max")
    func needsReplacementExceedsMax() {
        let gear = makeGear(totalDistanceKm: 900, maxDistanceKm: 800)
        #expect(gear.needsReplacement == true)
    }

    @Test("Does not need replacement when under max")
    func noReplacementUnderMax() {
        let gear = makeGear(totalDistanceKm: 500, maxDistanceKm: 800)
        #expect(gear.needsReplacement == false)
    }

    @Test("Does not need replacement when maxDistanceKm is zero")
    func noReplacementZeroMax() {
        let gear = makeGear(totalDistanceKm: 100, maxDistanceKm: 0)
        #expect(gear.needsReplacement == false)
    }

    // MARK: - Remaining Km

    @Test("Remaining km is correct with distance left")
    func remainingKmPositive() {
        let gear = makeGear(totalDistanceKm: 300, maxDistanceKm: 800)
        #expect(gear.remainingKm == 500)
    }

    @Test("Remaining km is zero when over max")
    func remainingKmZero() {
        let gear = makeGear(totalDistanceKm: 900, maxDistanceKm: 800)
        #expect(gear.remainingKm == 0)
    }

    @Test("Remaining km is max when no distance logged")
    func remainingKmFull() {
        let gear = makeGear(totalDistanceKm: 0, maxDistanceKm: 800)
        #expect(gear.remainingKm == 800)
    }
}
