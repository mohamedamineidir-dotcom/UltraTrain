import Foundation

enum WeekSkeletonBuilder {

    struct WeekSkeleton: Equatable, Sendable {
        let weekNumber: Int
        let startDate: Date
        let endDate: Date
        let phase: TrainingPhase
        let isRecoveryWeek: Bool
    }

    static func build(
        raceDate: Date,
        phases: [PhaseDistributor.PhaseAllocation],
        recoveryCycle: Int = AppConfiguration.Training.recoveryWeekCycle
    ) -> [WeekSkeleton] {
        let totalWeeks = phases.reduce(0) { $0 + $1.weekCount }

        // Work backward from race date — race week ends on race day's week start + 6 days
        let calendar = Calendar.current
        let raceWeekStart = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: raceDate)
        let raceWeekMonday = calendar.date(from: raceWeekStart) ?? raceDate
        let planStartDate = raceWeekMonday.adding(weeks: -(totalWeeks - 1))

        var skeletons: [WeekSkeleton] = []
        var weekIndex = 0
        var nonRecoveryCount = 0

        for allocation in phases {
            for phaseWeekIndex in 0..<allocation.weekCount {
                let startDate = planStartDate.adding(weeks: weekIndex)
                let endDate = startDate.adding(days: 6)

                let isLastPhaseWeek = phaseWeekIndex == allocation.weekCount - 1
                let isTaper = allocation.phase == .taper

                // Recovery every N-th non-recovery week, but never in taper
                let isRecovery: Bool
                if isTaper {
                    isRecovery = false
                } else {
                    nonRecoveryCount += 1
                    if nonRecoveryCount >= recoveryCycle && !isLastPhaseWeek {
                        isRecovery = true
                        nonRecoveryCount = 0
                    } else {
                        isRecovery = false
                    }
                }

                skeletons.append(WeekSkeleton(
                    weekNumber: weekIndex + 1,
                    startDate: startDate,
                    endDate: endDate,
                    phase: allocation.phase,
                    isRecoveryWeek: isRecovery
                ))
                weekIndex += 1
            }
        }
        return skeletons
    }
}
