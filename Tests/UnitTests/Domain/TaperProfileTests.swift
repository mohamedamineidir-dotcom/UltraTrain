import Foundation
import Testing
@testable import UltraTrain

@Suite("TaperProfile Tests")
struct TaperProfileTests {

    // MARK: - Race Category Selection

    @Test("100K+ race gets 5 taper weeks with 2 transition")
    func hundredKPlus() {
        let profile = TaperProfile.forRace(effectiveKm: 170)
        #expect(profile.totalTaperWeeks == 5)
        #expect(profile.volumeTransitionWeeks == 2)
        #expect(profile.weeklyVolumeFractions.count == 5)
        #expect(profile.qualityAllowedPerWeek.count == 5)
    }

    @Test("50-99K race gets 4 taper weeks with 1 transition")
    func fiftyToNinetyNine() {
        let profile = TaperProfile.forRace(effectiveKm: 80)
        #expect(profile.totalTaperWeeks == 4)
        #expect(profile.volumeTransitionWeeks == 1)
        #expect(profile.weeklyVolumeFractions.count == 4)
    }

    @Test("Marathon/Half race gets 2 taper weeks with no transition")
    func marathonHalf() {
        let profile = TaperProfile.forRace(effectiveKm: 42)
        #expect(profile.totalTaperWeeks == 2)
        #expect(profile.volumeTransitionWeeks == 0)
        #expect(profile.weeklyVolumeFractions.count == 2)
    }

    @Test("10K race gets 1 taper week")
    func tenK() {
        let profile = TaperProfile.forRace(effectiveKm: 10)
        #expect(profile.totalTaperWeeks == 1)
        #expect(profile.volumeTransitionWeeks == 0)
        #expect(profile.weeklyVolumeFractions.count == 1)
    }

    // MARK: - Boundary Values

    @Test("Exactly 100km uses 100K+ profile")
    func exactlyHundred() {
        let profile = TaperProfile.forRace(effectiveKm: 100)
        #expect(profile.totalTaperWeeks == 5)
    }

    @Test("Exactly 50km uses 50-99K profile")
    func exactlyFifty() {
        let profile = TaperProfile.forRace(effectiveKm: 50)
        #expect(profile.totalTaperWeeks == 4)
    }

    @Test("Exactly 21km uses Marathon/Half profile")
    func exactlyTwentyOne() {
        let profile = TaperProfile.forRace(effectiveKm: 21)
        #expect(profile.totalTaperWeeks == 2)
    }

    @Test("20.9km uses 10K profile")
    func justUnderTwentyOne() {
        let profile = TaperProfile.forRace(effectiveKm: 20.9)
        #expect(profile.totalTaperWeeks == 1)
    }

    // MARK: - Volume Fractions

    @Test("Volume fractions decrease monotonically")
    func monotonicDecrease() {
        for effKm in [10.0, 30.0, 80.0, 170.0] {
            let profile = TaperProfile.forRace(effectiveKm: effKm)
            for i in 1..<profile.weeklyVolumeFractions.count {
                #expect(
                    profile.weeklyVolumeFractions[i] < profile.weeklyVolumeFractions[i - 1],
                    "Fractions should decrease: week \(i) >= week \(i-1) for effKm=\(effKm)"
                )
            }
        }
    }

    @Test("First taper week fraction is >= 0.45 (smooth transition)")
    func firstWeekSmooth() {
        for effKm in [10.0, 30.0, 80.0, 170.0] {
            let profile = TaperProfile.forRace(effectiveKm: effKm)
            #expect(
                profile.weeklyVolumeFractions[0] >= 0.45,
                "First taper week should be >= 45% of peak for effKm=\(effKm)"
            )
        }
    }

    // MARK: - Sub-Phase Classification

    @Test("100K+ weeks 0-1 are volumeTransition, weeks 2-4 are trueTaper")
    func subPhaseClassification100K() {
        let profile = TaperProfile.forRace(effectiveKm: 170)
        #expect(profile.subPhase(forWeekInTaper: 0) == .volumeTransition)
        #expect(profile.subPhase(forWeekInTaper: 1) == .volumeTransition)
        #expect(profile.subPhase(forWeekInTaper: 2) == .trueTaper)
        #expect(profile.subPhase(forWeekInTaper: 3) == .trueTaper)
        #expect(profile.subPhase(forWeekInTaper: 4) == .trueTaper)
    }

    @Test("50-99K week 0 is volumeTransition, weeks 1-3 are trueTaper")
    func subPhaseClassification50K() {
        let profile = TaperProfile.forRace(effectiveKm: 80)
        #expect(profile.subPhase(forWeekInTaper: 0) == .volumeTransition)
        #expect(profile.subPhase(forWeekInTaper: 1) == .trueTaper)
    }

    @Test("Marathon/Half has no volumeTransition weeks")
    func subPhaseClassificationMarathon() {
        let profile = TaperProfile.forRace(effectiveKm: 42)
        #expect(profile.subPhase(forWeekInTaper: 0) == .trueTaper)
        #expect(profile.subPhase(forWeekInTaper: 1) == .trueTaper)
    }

    // MARK: - Quality Allowed

    @Test("100K+ quality allowed in transition weeks only")
    func qualityAllowed100K() {
        let profile = TaperProfile.forRace(effectiveKm: 170)
        #expect(profile.isQualityAllowed(forWeekInTaper: 0) == true)
        #expect(profile.isQualityAllowed(forWeekInTaper: 1) == true)
        #expect(profile.isQualityAllowed(forWeekInTaper: 2) == false)
        #expect(profile.isQualityAllowed(forWeekInTaper: 3) == false)
        #expect(profile.isQualityAllowed(forWeekInTaper: 4) == false)
    }

    @Test("Out-of-bounds week index returns false for quality")
    func outOfBoundsQuality() {
        let profile = TaperProfile.forRace(effectiveKm: 170)
        #expect(profile.isQualityAllowed(forWeekInTaper: 10) == false)
        #expect(profile.isQualityAllowed(forWeekInTaper: -1) == false)
    }

    @Test("Out-of-bounds week index returns last fraction for volume")
    func outOfBoundsVolume() {
        let profile = TaperProfile.forRace(effectiveKm: 170)
        let lastFraction = profile.weeklyVolumeFractions.last!
        #expect(profile.volumeFraction(forWeekInTaper: 10) == lastFraction)
    }
}
