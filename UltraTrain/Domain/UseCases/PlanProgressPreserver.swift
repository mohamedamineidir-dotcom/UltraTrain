import Foundation

enum PlanProgressPreserver {

    static func snapshot(_ plan: TrainingPlan) -> [SessionProgressSnapshot] {
        let calendar = Calendar.current
        return plan.weeks.flatMap { week in
            week.sessions
                .filter { $0.isCompleted || $0.isSkipped || $0.linkedRunId != nil }
                .map { session in
                    let dayOfWeek = calendar.component(.weekday, from: session.date)
                    let key = "\(week.weekNumber)-\(session.type.rawValue)-\(dayOfWeek)"
                    return SessionProgressSnapshot(
                        key: key,
                        isCompleted: session.isCompleted,
                        isSkipped: session.isSkipped,
                        linkedRunId: session.linkedRunId
                    )
                }
        }
    }

    static func restore(_ snapshots: [SessionProgressSnapshot], into plan: inout TrainingPlan) {
        let calendar = Calendar.current
        for weekIndex in plan.weeks.indices {
            let weekNumber = plan.weeks[weekIndex].weekNumber
            for sessionIndex in plan.weeks[weekIndex].sessions.indices {
                let session = plan.weeks[weekIndex].sessions[sessionIndex]
                let dayOfWeek = calendar.component(.weekday, from: session.date)
                let key = "\(weekNumber)-\(session.type.rawValue)-\(dayOfWeek)"
                if let match = snapshots.first(where: { $0.key == key }) {
                    plan.weeks[weekIndex].sessions[sessionIndex].isCompleted = match.isCompleted
                    plan.weeks[weekIndex].sessions[sessionIndex].isSkipped = match.isSkipped
                    plan.weeks[weekIndex].sessions[sessionIndex].linkedRunId = match.linkedRunId
                }
            }
        }
    }
}
