import Foundation
import Testing
@testable import UltraTrain

/// T5: ultras (100K+ effective km) need MORE aerobic base, not more peak.
/// Pre-fix the 100K+ shift moved 5% base→peak (wrong direction);
/// post-fix shifts 8% peak→base, getting closer to Roche/Koop/Jurek's
/// ~30–35% base recommendation for ultras.
@Suite("PhaseDistributor 100K+ Ultra Distribution Tests")
struct PhaseDistributorUltraTests {

    @Test("100K+ intermediate gets at least 5 base weeks on 24-week plan")
    func intermediate100KGetsMoreBase() {
        let result = PhaseDistributor.distribute(
            totalWeeks: 24,
            experience: .intermediate,
            raceEffectiveKm: 165 // 100K + 6500m D+
        )
        let base = result.first { $0.phase == .base }!.weekCount
        #expect(base >= 5,
                "100K+ intermediate 24wk plan should have ≥5 base weeks, got \(base)")
    }

    @Test("100K+ ultra has more base weeks than the same race configured under 100K threshold")
    func ultraGetsMoreBaseThanSubUltra() {
        let ultra = PhaseDistributor.distribute(
            totalWeeks: 24, experience: .intermediate, raceEffectiveKm: 165
        )
        let subUltra = PhaseDistributor.distribute(
            totalWeeks: 24, experience: .intermediate, raceEffectiveKm: 80
        )
        let ultraBase = ultra.first { $0.phase == .base }!.weekCount
        let subUltraBase = subUltra.first { $0.phase == .base }!.weekCount
        #expect(ultraBase > subUltraBase,
                "100K+ should have MORE base than sub-100K (was reversed pre-fix), got \(ultraBase) vs \(subUltraBase)")
    }

    @Test("100K+ ultra has fewer peak weeks than sub-100K")
    func ultraGetsFewerPeakThanSubUltra() {
        let ultra = PhaseDistributor.distribute(
            totalWeeks: 24, experience: .intermediate, raceEffectiveKm: 165
        )
        let subUltra = PhaseDistributor.distribute(
            totalWeeks: 24, experience: .intermediate, raceEffectiveKm: 80
        )
        let ultraPeak = ultra.first { $0.phase == .peak }!.weekCount
        let subUltraPeak = subUltra.first { $0.phase == .peak }!.weekCount
        #expect(ultraPeak < subUltraPeak,
                "100K+ should have LESS peak than sub-100K, got \(ultraPeak) vs \(subUltraPeak)")
    }

    @Test("100K+ peak fraction stays meaty (≥20%) — ultras still need a peak phase")
    func ultraPeakStillMeaty() {
        for experience in [ExperienceLevel.intermediate, .advanced, .elite] {
            let result = PhaseDistributor.distribute(
                totalWeeks: 24, experience: experience, raceEffectiveKm: 165
            )
            let peak = result.first { $0.phase == .peak }!.weekCount
            let totalNonTaper = result.filter { $0.phase != .taper }.reduce(0) { $0 + $1.weekCount }
            let peakFraction = Double(peak) / Double(totalNonTaper)
            #expect(peakFraction >= 0.25,
                    "\(experience) 100K+ peak should be ≥25% of non-taper, got \(peakFraction)")
        }
    }

    @Test("Sub-100K races (marathon, 50K) are unaffected by the ultra shift")
    func nonUltraUnaffected() {
        // Without raceEffectiveKm OR with raceEffectiveKm < 100, the
        // tier-default fractions apply directly.
        let withDefault = PhaseDistributor.distribute(
            totalWeeks: 20, experience: .intermediate, raceEffectiveKm: 0
        )
        let underThreshold = PhaseDistributor.distribute(
            totalWeeks: 20, experience: .intermediate, raceEffectiveKm: 50
        )
        let baseDefault = withDefault.first { $0.phase == .base }!.weekCount
        let baseUnder = underThreshold.first { $0.phase == .base }!.weekCount
        #expect(baseDefault == baseUnder,
                "Sub-100K races should match default behavior, got \(baseUnder) vs \(baseDefault)")
    }
}
