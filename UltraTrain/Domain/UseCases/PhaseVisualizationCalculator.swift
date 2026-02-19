import Foundation

enum PhaseVisualizationCalculator {

    static func computePhaseBlocks(from plan: TrainingPlan) -> [PhaseBlock] {
        let sortedWeeks = plan.weeks.sorted { $0.weekNumber < $1.weekNumber }
        guard !sortedWeeks.isEmpty else { return [] }

        let now = Date.now
        var blocks: [PhaseBlock] = []
        var currentPhase = sortedWeeks[0].phase
        var blockStart = sortedWeeks[0].startDate
        var blockWeekNumbers: [Int] = [sortedWeeks[0].weekNumber]

        for i in 1..<sortedWeeks.count {
            let week = sortedWeeks[i]
            if week.phase == currentPhase {
                blockWeekNumbers.append(week.weekNumber)
            } else {
                let blockEnd = sortedWeeks[i - 1].endDate
                let isCurrent = now >= blockStart && now <= blockEnd
                blocks.append(PhaseBlock(
                    id: UUID(),
                    phase: currentPhase,
                    startDate: blockStart,
                    endDate: blockEnd,
                    weekNumbers: blockWeekNumbers,
                    isCurrentPhase: isCurrent
                ))
                currentPhase = week.phase
                blockStart = week.startDate
                blockWeekNumbers = [week.weekNumber]
            }
        }

        let lastEnd = sortedWeeks.last!.endDate
        let isCurrent = now >= blockStart && now <= lastEnd
        blocks.append(PhaseBlock(
            id: UUID(),
            phase: currentPhase,
            startDate: blockStart,
            endDate: lastEnd,
            weekNumbers: blockWeekNumbers,
            isCurrentPhase: isCurrent
        ))

        return blocks
    }
}
