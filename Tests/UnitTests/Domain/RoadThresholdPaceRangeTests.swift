import Foundation
import Testing
@testable import UltraTrain

/// H1: cruise intervals should use the FASTER end of the threshold range
/// (1.06× of 5K), sustained tempos should use the SLOWER end (1.09×).
/// Pre-H1 the slower single value was always used, underspeeding cruise
/// prescriptions by ~6 sec/km for a sub-3 marathoner.
@Suite("RoadIntervalLibrary Threshold Pace Range Tests")
struct RoadThresholdPaceRangeTests {

    private func profile(fiveKPace: Double = 210) -> RoadPaceProfile {
        RoadPaceProfile(
            easyPacePerKm: (fiveKPace * 1.30)...(fiveKPace * 1.42),
            marathonPacePerKm: fiveKPace * 1.12,
            thresholdPacePerKm: fiveKPace * 1.09,
            thresholdPaceRangePerKm: (fiveKPace * 1.06)...(fiveKPace * 1.09),
            intervalPacePerKm: fiveKPace,
            repetitionPacePerKm: fiveKPace * 0.93,
            racePacePerKm: fiveKPace * 1.12,
            goalRealismLevel: .realistic,
            isDataDerived: true,
            recommendedGoalTime: nil
        )
    }

    /// Find a template by name from RoadIntervalLibrary.allTemplates.
    private func template(named name: String) -> RoadIntervalLibrary.Template {
        guard let t = RoadIntervalLibrary.allTemplates.first(where: { $0.name == name }) else {
            preconditionFailure("Template '\(name)' not found in library")
        }
        return t
    }

    // MARK: - Cruise intervals → faster end (1.06×)

    @Test("Cruise Intervals 1K (5×1km) prescribes faster end of threshold range")
    func cruise1KUsesFasterEnd() {
        let p = profile()
        let cruise = template(named: "Cruise Intervals 1K")
        let pace = cruise.effectiveThresholdPacePerKm(profile: p)
        #expect(pace == p.thresholdPaceRangePerKm.lowerBound,
                "5×1km cruise should use 1.06× (faster), got \(pace) vs expected \(p.thresholdPaceRangePerKm.lowerBound)")
    }

    @Test("Cruise Intervals 1600m (4×1600m) prescribes faster end")
    func cruise1600UsesFasterEnd() {
        let p = profile()
        let cruise = template(named: "Cruise Intervals 1600m")
        let pace = cruise.effectiveThresholdPacePerKm(profile: p)
        #expect(pace == p.thresholdPaceRangePerKm.lowerBound)
    }

    @Test("Threshold 5×5min uses faster end")
    func threshold5x5UsesFasterEnd() {
        let p = profile()
        let t = template(named: "Threshold 5×5min")
        #expect(t.effectiveThresholdPacePerKm(profile: p) == p.thresholdPaceRangePerKm.lowerBound)
    }

    @Test("Threshold Ladder 2K (3×2km, ~7 min/rep) uses faster end")
    func ladder2KUsesFasterEnd() {
        let p = profile()
        let ladder = template(named: "Threshold Ladder 2K")
        #expect(ladder.effectiveThresholdPacePerKm(profile: p) == p.thresholdPaceRangePerKm.lowerBound)
    }

    // MARK: - Sustained tempo → slower end (1.09×)

    @Test("Tempo 20min (single continuous block) uses slower end")
    func tempo20UsesSlowerEnd() {
        let p = profile()
        let t = template(named: "Tempo 20min")
        #expect(t.effectiveThresholdPacePerKm(profile: p) == p.thresholdPaceRangePerKm.upperBound)
    }

    @Test("Marathon Threshold 25min (single continuous block) uses slower end")
    func marathonThreshold25UsesSlowerEnd() {
        let p = profile()
        let t = template(named: "Marathon Threshold 25min")
        #expect(t.effectiveThresholdPacePerKm(profile: p) == p.thresholdPaceRangePerKm.upperBound)
    }

    @Test("Double Tempo (2×20min, long reps) uses slower end")
    func doubleTempoUsesSlowerEnd() {
        let p = profile()
        let t = template(named: "Double Tempo")
        // 40/2 = 20 min per rep — sustained, not cruise
        #expect(t.effectiveThresholdPacePerKm(profile: p) == p.thresholdPaceRangePerKm.upperBound)
    }

    @Test("Norwegian Double Threshold (2×4000m, ~14 min/rep) uses slower end")
    func norwegianUsesSlowerEnd() {
        let p = profile()
        let t = template(named: "Norwegian Double Threshold")
        #expect(t.effectiveThresholdPacePerKm(profile: p) == p.thresholdPaceRangePerKm.upperBound)
    }

    @Test("Progressive Tempo 30min (single block) uses slower end")
    func progressiveTempoUsesSlowerEnd() {
        let p = profile()
        let t = template(named: "Progressive Tempo 30min")
        #expect(t.effectiveThresholdPacePerKm(profile: p) == p.thresholdPaceRangePerKm.upperBound)
    }

    // MARK: - Concrete numbers (sanity)

    @Test("Faster vs slower end produces a meaningful pace gap (~6 sec/km)")
    func paceGap() {
        let p = profile(fiveKPace: 210) // 3:30/km 5K → 2h40 marathoner
        let cruise = template(named: "Cruise Intervals 1K")
            .effectiveThresholdPacePerKm(profile: p)
        let sustained = template(named: "Tempo 20min")
            .effectiveThresholdPacePerKm(profile: p)
        let gapSeconds = sustained - cruise
        // 1.09× - 1.06× = 0.03 × 210 = 6.3 sec/km
        #expect(gapSeconds >= 5 && gapSeconds <= 8,
                "Expected ~6 sec/km gap between cruise and sustained, got \(gapSeconds)")
    }
}
