import Foundation
import Testing
@testable import UltraTrain

@Suite("PlanProgressPreserver Tests")
struct PlanProgressPreserverTests {

    // MARK: - Helpers

    private func makePlan(
        weekNumber: Int = 1,
        sessionType: SessionType = .longRun,
        dayOffset: Int = 0,
        isCompleted: Bool = false,
        isSkipped: Bool = false,
        linkedRunId: UUID? = nil
    ) -> TrainingPlan {
        let weekStart = Date.now.startOfWeek.adding(weeks: weekNumber - 1)
        let sessionDate = weekStart.adding(days: dayOffset)

        let session = TrainingSession(
            id: UUID(),
            date: sessionDate,
            type: sessionType,
            plannedDistanceKm: 20,
            plannedElevationGainM: 500,
            plannedDuration: 7200,
            intensity: .moderate,
            description: "Test session",
            nutritionNotes: nil,
            isCompleted: isCompleted,
            isSkipped: isSkipped,
            linkedRunId: linkedRunId
        )

        let week = TrainingWeek(
            id: UUID(),
            weekNumber: weekNumber,
            startDate: weekStart,
            endDate: weekStart.adding(days: 6),
            phase: .base,
            sessions: [session],
            isRecoveryWeek: false,
            targetVolumeKm: 40,
            targetElevationGainM: 1000
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

    // MARK: - Snapshot Tests

    @Test("Snapshot captures completed sessions")
    func snapshotCapturesCompleted() {
        let plan = makePlan(
            weekNumber: 1,
            sessionType: .longRun,
            dayOffset: 0,
            isCompleted: true
        )

        let snapshots = PlanProgressPreserver.snapshot(plan)

        #expect(snapshots.count == 1)
        #expect(snapshots[0].isCompleted == true)
        #expect(snapshots[0].isSkipped == false)
    }

    @Test("Snapshot captures skipped sessions")
    func snapshotCapturesSkipped() {
        let plan = makePlan(
            weekNumber: 2,
            sessionType: .tempo,
            dayOffset: 1,
            isSkipped: true
        )

        let snapshots = PlanProgressPreserver.snapshot(plan)

        #expect(snapshots.count == 1)
        #expect(snapshots[0].isSkipped == true)
        #expect(snapshots[0].isCompleted == false)
    }

    @Test("Snapshot captures linkedRunId")
    func snapshotCapturesLinkedRunId() {
        let runId = UUID()
        let plan = makePlan(
            weekNumber: 1,
            sessionType: .intervals,
            dayOffset: 2,
            linkedRunId: runId
        )

        let snapshots = PlanProgressPreserver.snapshot(plan)

        #expect(snapshots.count == 1)
        #expect(snapshots[0].linkedRunId == runId)
    }

    @Test("Snapshot ignores sessions with no progress")
    func snapshotIgnoresNoProgress() {
        let plan = makePlan(
            weekNumber: 1,
            sessionType: .recovery,
            dayOffset: 0,
            isCompleted: false,
            isSkipped: false,
            linkedRunId: nil
        )

        let snapshots = PlanProgressPreserver.snapshot(plan)

        #expect(snapshots.isEmpty)
    }

    // MARK: - Restore Tests

    @Test("Restore applies progress to matching sessions")
    func restoreAppliesProgress() {
        let runId = UUID()
        // Create original plan with completed session
        let original = makePlan(
            weekNumber: 1,
            sessionType: .longRun,
            dayOffset: 0,
            isCompleted: true,
            linkedRunId: runId
        )

        let snapshots = PlanProgressPreserver.snapshot(original)

        // Create a new plan with the same structure but no progress
        var newPlan = makePlan(
            weekNumber: 1,
            sessionType: .longRun,
            dayOffset: 0,
            isCompleted: false,
            linkedRunId: nil
        )

        PlanProgressPreserver.restore(snapshots, into: &newPlan)

        let restoredSession = newPlan.weeks[0].sessions[0]
        #expect(restoredSession.isCompleted == true)
        #expect(restoredSession.linkedRunId == runId)
    }

    @Test("Restore does NOT apply progress to non-matching sessions")
    func restoreDoesNotApplyToNonMatching() {
        // Completed long run on day 0
        let original = makePlan(
            weekNumber: 1,
            sessionType: .longRun,
            dayOffset: 0,
            isCompleted: true
        )

        let snapshots = PlanProgressPreserver.snapshot(original)

        // New plan has a different session type on a different day
        var newPlan = makePlan(
            weekNumber: 1,
            sessionType: .tempo,
            dayOffset: 2,
            isCompleted: false
        )

        PlanProgressPreserver.restore(snapshots, into: &newPlan)

        let session = newPlan.weeks[0].sessions[0]
        #expect(session.isCompleted == false)
        #expect(session.isSkipped == false)
        #expect(session.linkedRunId == nil)
    }
}
