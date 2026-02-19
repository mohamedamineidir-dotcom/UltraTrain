import Foundation
import os

final class WidgetPendingActionProcessor: @unchecked Sendable {

    private let planRepository: any TrainingPlanRepository
    private let widgetDataWriter: WidgetDataWriter

    init(
        planRepository: any TrainingPlanRepository,
        widgetDataWriter: WidgetDataWriter
    ) {
        self.planRepository = planRepository
        self.widgetDataWriter = widgetDataWriter
    }

    func processPendingActions() async {
        guard let action = WidgetDataReader.readPendingAction() else { return }

        do {
            guard let plan = try await planRepository.getActivePlan() else {
                WidgetDataReader.clearPendingAction()
                return
            }

            let allSessions = plan.weeks.flatMap(\.sessions)
            guard var session = allSessions.first(where: { $0.id == action.sessionId }) else {
                Logger.widget.warning("Pending action session not found: \(action.sessionId)")
                WidgetDataReader.clearPendingAction()
                return
            }

            switch action.action {
            case "complete":
                session.isCompleted = true
            case "skip":
                session.isSkipped = true
            default:
                Logger.widget.warning("Unknown pending action: \(action.action)")
                WidgetDataReader.clearPendingAction()
                return
            }

            try await planRepository.updateSession(session)
            WidgetDataReader.clearPendingAction()
            await widgetDataWriter.writeAll()
            Logger.widget.info("Processed pending widget action: \(action.action) for session \(action.sessionId)")
        } catch {
            Logger.widget.error("Failed to process pending widget action: \(error)")
            WidgetDataReader.clearPendingAction()
        }
    }
}
