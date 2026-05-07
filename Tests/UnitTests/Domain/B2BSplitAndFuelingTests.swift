import Foundation
import Testing
@testable import UltraTrain

/// T10 + T11 + T12 quick polish tests.
@Suite("B2B Split + Recovery LR Elevation + Fueling Tests")
struct B2BSplitAndFuelingTests {

    // MARK: - T10 — B2B day split scales with race distance

    @Test("Sub-50K B2B uses 45/55 split")
    func sub50KSplit() {
        let s = LongRunCurveCalculator.b2bDaySplit(raceEffectiveKm: 45)
        #expect(s.day1 == 0.45)
        #expect(s.day2 == 0.55)
    }

    @Test("50–80K B2B keeps 43/57 (current default unchanged)")
    func midUltraSplit() {
        let s = LongRunCurveCalculator.b2bDaySplit(raceEffectiveKm: 65)
        #expect(s.day1 == 0.43)
        #expect(s.day2 == 0.57)
    }

    @Test("100K+ B2B uses 40/60 (day-2-heavier for second-half race rehearsal)")
    func ultraSplit() {
        for km in [100.0, 165.0, 250.0] {
            let s = LongRunCurveCalculator.b2bDaySplit(raceEffectiveKm: km)
            #expect(s.day1 == 0.40, "expected 0.40 for \(km)km, got \(s.day1)")
            #expect(s.day2 == 0.60)
        }
    }

    @Test("Zero raceEffectiveKm falls through to legacy 43/57")
    func zeroFallsThrough() {
        let s = LongRunCurveCalculator.b2bDaySplit(raceEffectiveKm: 0)
        #expect(s.day1 == 0.43)
        #expect(s.day2 == 0.57)
    }

    @Test("Splits always sum to 1.0")
    func splitsSumToOne() {
        for km in [10.0, 50.0, 80.0, 100.0, 200.0] {
            let s = LongRunCurveCalculator.b2bDaySplit(raceEffectiveKm: km)
            #expect(abs(s.day1 + s.day2 - 1.0) < 0.001,
                    "splits don't sum to 1 for \(km)km: \(s.day1) + \(s.day2)")
        }
    }
}
