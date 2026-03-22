import Foundation
import Testing
@testable import UltraTrain

@Suite("Weekly Review Handler Tests")
struct WeeklyReviewHandlerTests {

    // MARK: - Helpers

    private let calendar = Calendar.current

    private func makeSession(
        id: UUID = UUID(),
        date: Date,
        type: SessionType = .tempo,
        isCompleted: Bool = false,
        isSkipped: Bool = false,
        isKeySession: Bool = false,
        distanceKm: Double = 10,
        elevationGainM: Double = 200,
        duration: TimeInterval = 3600
    ) -> TrainingSession {
        var session = TrainingSession(
            id: id,
            date: date,
            type: type,
            plannedDistanceKm: distanceKm,
            plannedElevationGainM: elevationGainM,
            plannedDuration: duration,
            intensity: .moderate,
            description: "\(type.rawValue) session",
            nutritionNotes: nil,
            isCompleted: isCompleted,
            isSkipped: isSkipped,
            linkedRunId: nil
        )
        session.isKeySession = isKeySession
        return session
    }

    private func makeWeek(
        weekNumber: Int,
        startDate: Date,
        sessions: [TrainingSession]
    ) -> TrainingWeek {
        let endDate = calendar.date(byAdding: .day, value: 6, to: startDate)!
        return TrainingWeek(
            id: UUID(),
            weekNumber: weekNumber,
            startDate: startDate,
            endDate: endDate,
            phase: .build,
            sessions: sessions,
            isRecoveryWeek: false,
            targetVolumeKm: 50,
            targetElevationGainM: 1000
        )
    }

    private func makePlan(weeks: [TrainingWeek]) -> TrainingPlan {
        TrainingPlan(
            id: UUID(),
            athleteId: UUID(),
            targetRaceId: UUID(),
            createdAt: Date.distantPast,
            weeks: weeks,
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )
    }

    private func weekStart(daysFromNow offset: Int, from now: Date) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now))!
    }

    // MARK: - checkReviewNeeded

    @Test("Review needed when previous week has zero completed non-rest sessions")
    func reviewNeededZeroCompleted() {
        let now = Date()
        let prevStart = weekStart(daysFromNow: -10, from: now)
        let currStart = weekStart(daysFromNow: -3, from: now)

        let s1 = makeSession(date: calendar.date(byAdding: .day, value: 1, to: prevStart)!, type: .longRun)
        let s2 = makeSession(date: calendar.date(byAdding: .day, value: 3, to: prevStart)!, type: .tempo)

        let prevWeek = makeWeek(weekNumber: 1, startDate: prevStart, sessions: [s1, s2])
        let currWeek = makeWeek(weekNumber: 2, startDate: currStart, sessions: [])
        let plan = makePlan(weeks: [prevWeek, currWeek])

        let result = WeeklyReviewHandler.checkReviewNeeded(plan: plan, lastReviewedWeekNumber: 0, now: now)
        #expect(result.isNeeded)
        #expect(result.previousWeekIndex == 0)
        #expect(result.previousWeekNumber == 1)
        #expect(result.nonRestSessions.count == 2)
    }

    @Test("Review not needed when previous week has completed sessions")
    func notNeededWhenCompleted() {
        let now = Date()
        let prevStart = weekStart(daysFromNow: -10, from: now)
        let currStart = weekStart(daysFromNow: -3, from: now)

        let s1 = makeSession(date: calendar.date(byAdding: .day, value: 1, to: prevStart)!, type: .longRun, isCompleted: true)
        let s2 = makeSession(date: calendar.date(byAdding: .day, value: 3, to: prevStart)!, type: .tempo)

        let prevWeek = makeWeek(weekNumber: 1, startDate: prevStart, sessions: [s1, s2])
        let currWeek = makeWeek(weekNumber: 2, startDate: currStart, sessions: [])
        let plan = makePlan(weeks: [prevWeek, currWeek])

        let result = WeeklyReviewHandler.checkReviewNeeded(plan: plan, lastReviewedWeekNumber: 0, now: now)
        #expect(!result.isNeeded)
    }

    @Test("Review not needed when already reviewed")
    func notNeededAlreadyReviewed() {
        let now = Date()
        let prevStart = weekStart(daysFromNow: -10, from: now)
        let currStart = weekStart(daysFromNow: -3, from: now)

        let s1 = makeSession(date: calendar.date(byAdding: .day, value: 1, to: prevStart)!, type: .longRun)
        let prevWeek = makeWeek(weekNumber: 1, startDate: prevStart, sessions: [s1])
        let currWeek = makeWeek(weekNumber: 2, startDate: currStart, sessions: [])
        let plan = makePlan(weeks: [prevWeek, currWeek])

        let result = WeeklyReviewHandler.checkReviewNeeded(plan: plan, lastReviewedWeekNumber: 1, now: now)
        #expect(!result.isNeeded)
    }

    @Test("Review not needed for first week (no previous)")
    func notNeededFirstWeek() {
        let now = Date()
        let currStart = weekStart(daysFromNow: -3, from: now)
        let currWeek = makeWeek(weekNumber: 1, startDate: currStart, sessions: [])
        let plan = makePlan(weeks: [currWeek])

        let result = WeeklyReviewHandler.checkReviewNeeded(plan: plan, lastReviewedWeekNumber: 0, now: now)
        #expect(!result.isNeeded)
    }

    @Test("Review not needed when no active plan week")
    func notNeededNoPlanWeek() {
        let now = Date()
        let pastStart = weekStart(daysFromNow: -20, from: now)
        let week = makeWeek(weekNumber: 1, startDate: pastStart, sessions: [])
        let plan = makePlan(weeks: [week])

        let result = WeeklyReviewHandler.checkReviewNeeded(plan: plan, lastReviewedWeekNumber: 0, now: now)
        #expect(!result.isNeeded)
    }

    @Test("Review not needed when previous week only has rest sessions")
    func notNeededOnlyRest() {
        let now = Date()
        let prevStart = weekStart(daysFromNow: -10, from: now)
        let currStart = weekStart(daysFromNow: -3, from: now)

        let s1 = makeSession(date: calendar.date(byAdding: .day, value: 1, to: prevStart)!, type: .rest)
        let s2 = makeSession(date: calendar.date(byAdding: .day, value: 2, to: prevStart)!, type: .rest)

        let prevWeek = makeWeek(weekNumber: 1, startDate: prevStart, sessions: [s1, s2])
        let currWeek = makeWeek(weekNumber: 2, startDate: currStart, sessions: [])
        let plan = makePlan(weeks: [prevWeek, currWeek])

        let result = WeeklyReviewHandler.checkReviewNeeded(plan: plan, lastReviewedWeekNumber: 0, now: now)
        #expect(!result.isNeeded)
    }

    @Test("Non-rest sessions correctly excludes rest type")
    func nonRestSessionsExcludeRest() {
        let now = Date()
        let prevStart = weekStart(daysFromNow: -10, from: now)
        let currStart = weekStart(daysFromNow: -3, from: now)

        let s1 = makeSession(date: calendar.date(byAdding: .day, value: 1, to: prevStart)!, type: .longRun)
        let s2 = makeSession(date: calendar.date(byAdding: .day, value: 2, to: prevStart)!, type: .rest)
        let s3 = makeSession(date: calendar.date(byAdding: .day, value: 3, to: prevStart)!, type: .intervals)

        let prevWeek = makeWeek(weekNumber: 1, startDate: prevStart, sessions: [s1, s2, s3])
        let currWeek = makeWeek(weekNumber: 2, startDate: currStart, sessions: [])
        let plan = makePlan(weeks: [prevWeek, currWeek])

        let result = WeeklyReviewHandler.checkReviewNeeded(plan: plan, lastReviewedWeekNumber: 0, now: now)
        #expect(result.nonRestSessions.count == 2)
        for session in result.nonRestSessions {
            #expect(session.type != .rest)
        }
    }

    // MARK: - applyOutcome

    @Test("allCompleted marks all sessions completed with no volume reduction")
    func allCompletedOutcome() {
        let now = Date()
        let prevStart = weekStart(daysFromNow: -10, from: now)
        let s1 = makeSession(date: calendar.date(byAdding: .day, value: 1, to: prevStart)!, type: .longRun)
        let s2 = makeSession(date: calendar.date(byAdding: .day, value: 3, to: prevStart)!, type: .tempo)
        let week = makeWeek(weekNumber: 1, startDate: prevStart, sessions: [s1, s2])
        let plan = makePlan(weeks: [week])

        let (updated, needsReduction) = WeeklyReviewHandler.applyOutcome(.allCompleted, plan: plan, previousWeekIndex: 0)
        #expect(!needsReduction)
        for session in updated {
            #expect(session.isCompleted)
        }
        #expect(updated.count == 2)
    }

    @Test("noneCompleted marks all sessions skipped with volume reduction")
    func noneCompletedOutcome() {
        let now = Date()
        let prevStart = weekStart(daysFromNow: -10, from: now)
        let s1 = makeSession(date: calendar.date(byAdding: .day, value: 1, to: prevStart)!, type: .longRun)
        let s2 = makeSession(date: calendar.date(byAdding: .day, value: 3, to: prevStart)!, type: .tempo)
        let week = makeWeek(weekNumber: 1, startDate: prevStart, sessions: [s1, s2])
        let plan = makePlan(weeks: [week])

        let (updated, needsReduction) = WeeklyReviewHandler.applyOutcome(.noneCompleted, plan: plan, previousWeekIndex: 0)
        #expect(needsReduction)
        for session in updated {
            #expect(session.isSkipped)
        }
        #expect(updated.count == 2)
    }

    @Test("partiallyCompleted marks correct sessions completed and skipped")
    func partiallyCompletedOutcome() {
        let now = Date()
        let prevStart = weekStart(daysFromNow: -10, from: now)
        let id1 = UUID()
        let id2 = UUID()
        let s1 = makeSession(id: id1, date: calendar.date(byAdding: .day, value: 1, to: prevStart)!, type: .longRun)
        let s2 = makeSession(id: id2, date: calendar.date(byAdding: .day, value: 3, to: prevStart)!, type: .tempo)
        let week = makeWeek(weekNumber: 1, startDate: prevStart, sessions: [s1, s2])
        let plan = makePlan(weeks: [week])

        let (updated, _) = WeeklyReviewHandler.applyOutcome(
            .partiallyCompleted(completedIds: [id1]),
            plan: plan,
            previousWeekIndex: 0
        )
        let completed = updated.first { $0.id == id1 }
        let skipped = updated.first { $0.id == id2 }
        #expect(completed?.isCompleted == true)
        #expect(skipped?.isSkipped == true)
    }

    @Test("partiallyCompleted with missed key session triggers volume reduction")
    func partialMissedKeySession() {
        let now = Date()
        let prevStart = weekStart(daysFromNow: -10, from: now)
        let id1 = UUID()
        let id2 = UUID()
        let s1 = makeSession(id: id1, date: calendar.date(byAdding: .day, value: 1, to: prevStart)!, type: .recovery)
        let s2 = makeSession(id: id2, date: calendar.date(byAdding: .day, value: 3, to: prevStart)!, type: .longRun, isKeySession: true)
        let week = makeWeek(weekNumber: 1, startDate: prevStart, sessions: [s1, s2])
        let plan = makePlan(weeks: [week])

        let (_, needsReduction) = WeeklyReviewHandler.applyOutcome(
            .partiallyCompleted(completedIds: [id1]),
            plan: plan,
            previousWeekIndex: 0
        )
        #expect(needsReduction)
    }

    @Test("partiallyCompleted with all key sessions done does not trigger reduction")
    func partialAllKeyDone() {
        let now = Date()
        let prevStart = weekStart(daysFromNow: -10, from: now)
        let id1 = UUID()
        let id2 = UUID()
        let s1 = makeSession(id: id1, date: calendar.date(byAdding: .day, value: 1, to: prevStart)!, type: .longRun, isKeySession: true)
        let s2 = makeSession(id: id2, date: calendar.date(byAdding: .day, value: 3, to: prevStart)!, type: .recovery)
        let week = makeWeek(weekNumber: 1, startDate: prevStart, sessions: [s1, s2])
        let plan = makePlan(weeks: [week])

        let (_, needsReduction) = WeeklyReviewHandler.applyOutcome(
            .partiallyCompleted(completedIds: [id1]),
            plan: plan,
            previousWeekIndex: 0
        )
        #expect(!needsReduction)
    }

    // MARK: - reduceCurrentWeekVolume

    @Test("Volume reduction applies correct factor to future sessions")
    func volumeReductionAppliesFactor() {
        let now = Date()
        let currStart = weekStart(daysFromNow: -1, from: now)
        let futureDate = calendar.date(byAdding: .day, value: 2, to: currStart)!
        let s1 = makeSession(date: futureDate, type: .tempo, distanceKm: 10, elevationGainM: 200, duration: 3600)
        let week = makeWeek(weekNumber: 1, startDate: currStart, sessions: [s1])
        let plan = makePlan(weeks: [week])

        let reduced = WeeklyReviewHandler.reduceCurrentWeekVolume(plan: plan, currentWeekIndex: 0, reductionPercent: 20)
        #expect(reduced.count == 1)
        #expect(reduced[0].plannedDistanceKm == 8.0)
        #expect(reduced[0].plannedElevationGainM == 160.0)
        #expect(reduced[0].plannedDuration == 2880.0)
    }

    @Test("Volume reduction skips rest and completed sessions")
    func volumeReductionSkipsRestAndCompleted() {
        let now = Date()
        let currStart = weekStart(daysFromNow: -1, from: now)
        let futureDate = calendar.date(byAdding: .day, value: 2, to: currStart)!
        let s1 = makeSession(date: futureDate, type: .rest, distanceKm: 0)
        let s2 = makeSession(date: futureDate, type: .tempo, isCompleted: true, distanceKm: 10)
        let s3 = makeSession(date: futureDate, type: .longRun, distanceKm: 20)
        let week = makeWeek(weekNumber: 1, startDate: currStart, sessions: [s1, s2, s3])
        let plan = makePlan(weeks: [week])

        let reduced = WeeklyReviewHandler.reduceCurrentWeekVolume(plan: plan, currentWeekIndex: 0, reductionPercent: 20)
        #expect(reduced.count == 1)
        #expect(reduced[0].type == .longRun)
    }
}
