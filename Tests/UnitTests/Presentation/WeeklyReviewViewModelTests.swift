import Foundation
import Testing
@testable import UltraTrain

@Suite("Weekly Review ViewModel Tests")
struct WeeklyReviewViewModelTests {

    // MARK: - Helpers

    private let calendar = Calendar.current

    private func makeSession(
        id: UUID = UUID(),
        date: Date,
        type: SessionType = .tempo,
        isKeySession: Bool = false
    ) -> TrainingSession {
        var session = TrainingSession(
            id: id,
            date: date,
            type: type,
            plannedDistanceKm: 10,
            plannedElevationGainM: 200,
            plannedDuration: 3600,
            intensity: .moderate,
            description: "\(type.rawValue) session",
            nutritionNotes: nil,
            isCompleted: false,
            isSkipped: false,
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

    private func weekStart(daysFromNow offset: Int, from now: Date = .now) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now))!
    }

    // MARK: - Tests

    @Test("handleAllCompleted marks sessions and transitions to loading")
    @MainActor
    func allCompletedTransitions() async {
        let now = Date()
        let prevStart = weekStart(daysFromNow: -10, from: now)
        let s1 = makeSession(date: calendar.date(byAdding: .day, value: 1, to: prevStart)!, type: .longRun)
        let s2 = makeSession(date: calendar.date(byAdding: .day, value: 3, to: prevStart)!, type: .tempo)
        let week = makeWeek(weekNumber: 1, startDate: prevStart, sessions: [s1, s2])
        let plan = makePlan(weeks: [week])

        let repo = MockTrainingPlanRepository()
        let vm = WeeklyReviewViewModel(
            planRepository: repo,
            plan: plan,
            previousWeekIndex: 0,
            previousWeekNumber: 1,
            nonRestSessions: [s1, s2]
        )

        await vm.handleAllCompleted()
        #expect(vm.phase == .loading)
        #expect(repo.updatedSessions.count == 2)
        for session in repo.updatedSessions {
            #expect(session.isCompleted)
        }
    }

    @Test("handleNoneCompleted marks sessions skipped and transitions to loading")
    @MainActor
    func noneCompletedTransitions() async {
        let now = Date()
        let prevStart = weekStart(daysFromNow: -10, from: now)
        let s1 = makeSession(date: calendar.date(byAdding: .day, value: 1, to: prevStart)!, type: .longRun)
        let week = makeWeek(weekNumber: 1, startDate: prevStart, sessions: [s1])
        let plan = makePlan(weeks: [week])

        let repo = MockTrainingPlanRepository()
        let vm = WeeklyReviewViewModel(
            planRepository: repo,
            plan: plan,
            previousWeekIndex: 0,
            previousWeekNumber: 1,
            nonRestSessions: [s1]
        )

        await vm.handleNoneCompleted()
        #expect(vm.phase == .loading)
        #expect(repo.updatedSessions.contains { $0.isSkipped })
    }

    @Test("handlePartialCompleted marks selected and transitions to loading")
    @MainActor
    func partialCompletedTransitions() async {
        let now = Date()
        let prevStart = weekStart(daysFromNow: -10, from: now)
        let id1 = UUID()
        let id2 = UUID()
        let s1 = makeSession(id: id1, date: calendar.date(byAdding: .day, value: 1, to: prevStart)!, type: .longRun)
        let s2 = makeSession(id: id2, date: calendar.date(byAdding: .day, value: 3, to: prevStart)!, type: .tempo)
        let week = makeWeek(weekNumber: 1, startDate: prevStart, sessions: [s1, s2])
        let plan = makePlan(weeks: [week])

        let repo = MockTrainingPlanRepository()
        let vm = WeeklyReviewViewModel(
            planRepository: repo,
            plan: plan,
            previousWeekIndex: 0,
            previousWeekNumber: 1,
            nonRestSessions: [s1, s2]
        )
        vm.selectedCompletedIds = [id1]

        await vm.handlePartialCompleted()
        #expect(vm.phase == .loading)
        let completed = repo.updatedSessions.first { $0.id == id1 }
        let skipped = repo.updatedSessions.first { $0.id == id2 }
        #expect(completed?.isCompleted == true)
        #expect(skipped?.isSkipped == true)
    }

    @Test("showSessionPicker sets phase to sessionPicker")
    @MainActor
    func showSessionPickerPhase() {
        let plan = makePlan(weeks: [])
        let repo = MockTrainingPlanRepository()
        let vm = WeeklyReviewViewModel(
            planRepository: repo,
            plan: plan,
            previousWeekIndex: 0,
            previousWeekNumber: 1,
            nonRestSessions: []
        )

        vm.showSessionPicker()
        #expect(vm.phase == .sessionPicker)
    }

    @Test("onLoadingComplete sets phase to done")
    @MainActor
    func loadingCompleteSetsPhase() {
        let plan = makePlan(weeks: [])
        let repo = MockTrainingPlanRepository()
        let vm = WeeklyReviewViewModel(
            planRepository: repo,
            plan: plan,
            previousWeekIndex: 0,
            previousWeekNumber: 1,
            nonRestSessions: []
        )

        vm.onLoadingComplete()
        #expect(vm.phase == .done)
    }

    @Test("handleNoneCompleted with current week reduces volume")
    @MainActor
    func noneCompletedReducesVolume() async {
        let now = Date()
        let prevStart = weekStart(daysFromNow: -10, from: now)
        let currStart = weekStart(daysFromNow: -3, from: now)

        let s1 = makeSession(date: calendar.date(byAdding: .day, value: 1, to: prevStart)!, type: .longRun)
        let futureDate = calendar.date(byAdding: .day, value: 4, to: currStart)!
        let s2 = makeSession(date: futureDate, type: .tempo)

        let prevWeek = makeWeek(weekNumber: 1, startDate: prevStart, sessions: [s1])
        let currWeek = makeWeek(weekNumber: 2, startDate: currStart, sessions: [s2])
        let plan = makePlan(weeks: [prevWeek, currWeek])

        let repo = MockTrainingPlanRepository()
        let vm = WeeklyReviewViewModel(
            planRepository: repo,
            plan: plan,
            previousWeekIndex: 0,
            previousWeekNumber: 1,
            nonRestSessions: [s1]
        )

        await vm.handleNoneCompleted()
        #expect(vm.phase == .loading)
        let reducedSessions = repo.updatedSessions.filter { $0.plannedDistanceKm < 10 }
        #expect(reducedSessions.count >= 1)
    }
}
