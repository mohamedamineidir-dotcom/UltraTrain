import Foundation

/// Computes the athlete's current menstrual-cycle phase from a stored
/// `lastPeriodStartDate` + `cycleLengthDays`. Supports four canonical
/// phases. Used to surface coach advice on luteal-phase hard sessions
/// and (optionally) scale intensity slightly during that window.
///
/// Research basis:
///   • Sims 2016 — luteal-phase carbohydrate demand rises ~10-15% on
///     long efforts; HR runs slightly elevated for the same effort.
///   • Mountjoy 2014 (IOC RED-S) — chronic energy deficit during
///     menstruation impairs adaptation and signals overtraining risk.
///
/// Phase model (28-day baseline, scaled to actual cycle length):
///   • Days 1-5  : menstrual
///   • Days 6-13 : follicular (energy + HR are highest)
///   • Days 14-16: ovulation
///   • Days 17-28: luteal (carb demand up, HR runs warm)
enum CyclePhaseCalculator {

    enum Phase: String, Sendable {
        case menstrual
        case follicular
        case ovulation
        case luteal
        case unknown
    }

    /// Returns the current phase given the cycle anchor + length, or
    /// `.unknown` when inputs are missing / nonsensical. `now` is
    /// injectable for tests.
    static func currentPhase(
        lastPeriodStartDate: Date?,
        cycleLengthDays: Int,
        now: Date = .now
    ) -> Phase {
        guard let anchor = lastPeriodStartDate,
              cycleLengthDays >= 21, cycleLengthDays <= 40 else {
            return .unknown
        }

        let calendar = Calendar.current
        let anchorDay = calendar.startOfDay(for: anchor)
        let today = calendar.startOfDay(for: now)
        guard let elapsedDays = calendar.dateComponents([.day], from: anchorDay, to: today).day,
              elapsedDays >= 0 else {
            return .unknown
        }
        // Wrap into a single cycle.
        let dayInCycle = (elapsedDays % cycleLengthDays) + 1 // 1-indexed for readability

        // Scale the canonical 28-day phase boundaries to the actual cycle
        // length. Holds the menstrual + ovulation windows (biology),
        // stretches/contracts the follicular and luteal windows.
        let scale = Double(cycleLengthDays) / 28.0
        let menstrualEnd = Int((5.0 * scale).rounded())
        let follicularEnd = Int((13.0 * scale).rounded())
        let ovulationEnd = Int((16.0 * scale).rounded())

        switch dayInCycle {
        case ...menstrualEnd:                    return .menstrual
        case (menstrualEnd + 1)...follicularEnd: return .follicular
        case (follicularEnd + 1)...ovulationEnd: return .ovulation
        default:                                  return .luteal
        }
    }
}
