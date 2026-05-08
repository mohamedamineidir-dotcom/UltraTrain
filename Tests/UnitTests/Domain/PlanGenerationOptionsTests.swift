import Foundation
import Testing
@testable import UltraTrain

@Suite("PlanGenerationOptions")
struct PlanGenerationOptionsTests {

    @Test("anchorMultiplier maps each RecentFitnessChange severity")
    func anchorMultiplierMapping() {
        #expect(RecentFitnessChange.none.anchorMultiplier == 1.00)
        #expect(RecentFitnessChange.minor.anchorMultiplier == 0.92)
        #expect(RecentFitnessChange.moderate.anchorMultiplier == 0.80)
        #expect(RecentFitnessChange.significant.anchorMultiplier == 0.70)
    }

    @Test("Standard options has fitness test off + no fitness change")
    func standardDefaults() {
        let s = PlanGenerationOptions.standard
        #expect(s.includeFitnessTest == false)
        #expect(s.recentFitnessChange == nil)
    }

    @Test("Multiplier shrinks weeklyVolumeKm at expected ratio")
    func anchorMultiplierAppliedCorrectly() {
        // Sanity check: a 50 km/wk athlete reporting moderate setback
        // (4 weeks off, managed injury) → 50 × 0.80 = 40 km/wk anchor.
        let baseline = 50.0
        let multiplier = RecentFitnessChange.moderate.anchorMultiplier
        let anchored = baseline * multiplier
        #expect(abs(anchored - 40.0) < 0.01)
    }
}
