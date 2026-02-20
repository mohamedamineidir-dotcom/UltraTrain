import Foundation
import Testing
@testable import UltraTrain

@Suite("Widget Pending Action Processor Tests", .serialized)
struct WidgetPendingActionProcessorTests {

    private let sharedDefaults = UserDefaults(suiteName: WidgetDataKeys.suiteName)!

    private func makeSession(
        id: UUID = UUID(),
        date: Date = .now,
        type: SessionType = .longRun
    ) -> TrainingSession {
        TrainingSession(
            id: id,
            date: date,
            type: type,
            plannedDistanceKm: 20,
            plannedElevationGainM: 500,
            plannedDuration: 5400,
            intensity: .moderate,
            description: "Test session",
            nutritionNotes: nil,
            isCompleted: false,
            isSkipped: false,
            linkedRunId: nil
        )
    }

    private func makePlan(sessions: [TrainingSession]) -> TrainingPlan {
        let week = TrainingWeek(
            id: UUID(),
            weekNumber: 5,
            startDate: Date.now.startOfWeek,
            endDate: Date.now.startOfWeek.adding(days: 6),
            phase: .build,
            sessions: sessions,
            isRecoveryWeek: false,
            targetVolumeKm: 60,
            targetElevationGainM: 1500
        )
        return TrainingPlan(
            id: UUID(),
            athleteId: UUID(),
            targetRaceId: UUID(),
            createdAt: .now,
            weeks: [week],
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )
    }

    private func writePendingAction(sessionId: UUID, action: String) {
        let pendingAction = WidgetPendingAction(sessionId: sessionId, action: action, timestamp: .now)
        let encoded = try! JSONEncoder().encode(pendingAction)
        sharedDefaults.set(encoded, forKey: WidgetDataKeys.pendingAction)
        sharedDefaults.synchronize()
    }

    private func clearPendingAction() {
        sharedDefaults.removeObject(forKey: WidgetDataKeys.pendingAction)
        sharedDefaults.synchronize()
    }

    @Test("Marks session complete via pending action")
    func marksSessionComplete() async {
        let sessionId = UUID()
        let planRepo = MockTrainingPlanRepository()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date.now.startOfDay)!
        planRepo.activePlan = makePlan(sessions: [
            makeSession(id: sessionId, date: tomorrow)
        ])

        let writer = WidgetDataWriter(
            planRepository: planRepo,
            runRepository: MockRunRepository(),
            raceRepository: MockRaceRepository(),
            defaults: UserDefaults(suiteName: "test.processor.complete.\(UUID().uuidString)")
        )
        let processor = WidgetPendingActionProcessor(
            planRepository: planRepo,
            widgetDataWriter: writer
        )

        writePendingAction(sessionId: sessionId, action: "complete")

        await processor.processPendingActions()

        #expect(planRepo.updatedSession != nil)
        #expect(planRepo.updatedSession?.isCompleted == true)
        #expect(planRepo.updatedSession?.isSkipped == false)

        clearPendingAction()
    }

    @Test("Skips session via pending action")
    func skipsSession() async {
        let sessionId = UUID()
        let planRepo = MockTrainingPlanRepository()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date.now.startOfDay)!
        planRepo.activePlan = makePlan(sessions: [
            makeSession(id: sessionId, date: tomorrow)
        ])

        let writer = WidgetDataWriter(
            planRepository: planRepo,
            runRepository: MockRunRepository(),
            raceRepository: MockRaceRepository(),
            defaults: UserDefaults(suiteName: "test.processor.skip.\(UUID().uuidString)")
        )
        let processor = WidgetPendingActionProcessor(
            planRepository: planRepo,
            widgetDataWriter: writer
        )

        writePendingAction(sessionId: sessionId, action: "skip")

        await processor.processPendingActions()

        #expect(planRepo.updatedSession != nil)
        #expect(planRepo.updatedSession?.isSkipped == true)
        #expect(planRepo.updatedSession?.isCompleted == false)

        clearPendingAction()
    }

    @Test("No pending action does nothing")
    func noPendingAction() async {
        let planRepo = MockTrainingPlanRepository()
        let writer = WidgetDataWriter(
            planRepository: planRepo,
            runRepository: MockRunRepository(),
            raceRepository: MockRaceRepository(),
            defaults: UserDefaults(suiteName: "test.processor.none.\(UUID().uuidString)")
        )
        let processor = WidgetPendingActionProcessor(
            planRepository: planRepo,
            widgetDataWriter: writer
        )

        clearPendingAction()

        await processor.processPendingActions()

        #expect(planRepo.updatedSession == nil)
    }

    @Test("Clears action after processing")
    func clearsActionAfterProcessing() async {
        let sessionId = UUID()
        let planRepo = MockTrainingPlanRepository()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date.now.startOfDay)!
        planRepo.activePlan = makePlan(sessions: [
            makeSession(id: sessionId, date: tomorrow)
        ])

        let writer = WidgetDataWriter(
            planRepository: planRepo,
            runRepository: MockRunRepository(),
            raceRepository: MockRaceRepository(),
            defaults: UserDefaults(suiteName: "test.processor.clear.\(UUID().uuidString)")
        )
        let processor = WidgetPendingActionProcessor(
            planRepository: planRepo,
            widgetDataWriter: writer
        )

        writePendingAction(sessionId: sessionId, action: "complete")

        await processor.processPendingActions()

        let remaining = WidgetDataReader.readPendingAction()
        #expect(remaining == nil)
    }
}
