import Foundation
import Testing
@testable import UltraTrain

@Suite("SessionMatcher Tests")
struct SessionMatcherTests {

    private let today = Date.now
    private let calendar = Calendar.current

    private func makeSession(
        date: Date? = nil,
        type: SessionType = .longRun,
        distanceKm: Double = 15,
        duration: TimeInterval = 5400,
        isCompleted: Bool = false,
        isSkipped: Bool = false,
        linkedRunId: UUID? = nil
    ) -> TrainingSession {
        TrainingSession(
            id: UUID(),
            date: date ?? today,
            type: type,
            plannedDistanceKm: distanceKm,
            plannedElevationGainM: 500,
            plannedDuration: duration,
            intensity: .moderate,
            description: "Test session",
            nutritionNotes: nil,
            isCompleted: isCompleted,
            isSkipped: isSkipped,
            linkedRunId: linkedRunId
        )
    }

    // MARK: - Single Candidate

    @Test("Single same-day candidate matches with high confidence")
    func singleSameDayCandidate() {
        let session = makeSession(distanceKm: 15, duration: 5400)
        let result = SessionMatcher.findMatch(
            runDate: today,
            distanceKm: 14,
            duration: 5000,
            candidates: [session]
        )
        #expect(result != nil)
        #expect(result?.session.id == session.id)
        #expect(result?.confidence == 0.95)
    }

    // MARK: - Multiple Candidates

    @Test("Multiple same-day candidates selects best match by distance and duration")
    func multipleSameDayBestMatch() {
        let close = makeSession(distanceKm: 10, duration: 3600)
        let far = makeSession(distanceKm: 42, duration: 14400)

        let result = SessionMatcher.findMatch(
            runDate: today,
            distanceKm: 11,
            duration: 3800,
            candidates: [close, far]
        )

        #expect(result != nil)
        #expect(result?.session.id == close.id)
    }

    @Test("Exact match scores highest")
    func exactMatchScoresHighest() {
        let exact = makeSession(distanceKm: 20, duration: 7200)
        let close = makeSession(distanceKm: 18, duration: 6800)

        let result = SessionMatcher.findMatch(
            runDate: today,
            distanceKm: 20,
            duration: 7200,
            candidates: [close, exact]
        )

        #expect(result?.session.id == exact.id)
        #expect(result!.confidence > 0.85)
    }

    // MARK: - Exclusions

    @Test("Completed sessions are excluded")
    func completedExcluded() {
        let session = makeSession(isCompleted: true)
        let result = SessionMatcher.findMatch(
            runDate: today,
            distanceKm: 15,
            duration: 5400,
            candidates: [session]
        )
        #expect(result == nil)
    }

    @Test("Skipped sessions are excluded")
    func skippedExcluded() {
        let session = makeSession(isSkipped: true)
        let result = SessionMatcher.findMatch(
            runDate: today,
            distanceKm: 15,
            duration: 5400,
            candidates: [session]
        )
        #expect(result == nil)
    }

    @Test("Rest sessions are excluded")
    func restExcluded() {
        let session = makeSession(type: .rest)
        let result = SessionMatcher.findMatch(
            runDate: today,
            distanceKm: 15,
            duration: 5400,
            candidates: [session]
        )
        #expect(result == nil)
    }

    @Test("Sessions with existing linkedRunId are excluded")
    func alreadyLinkedExcluded() {
        let session = makeSession(linkedRunId: UUID())
        let result = SessionMatcher.findMatch(
            runDate: today,
            distanceKm: 15,
            duration: 5400,
            candidates: [session]
        )
        #expect(result == nil)
    }

    // MARK: - No Match

    @Test("Empty candidates returns nil")
    func emptyCandidates() {
        let result = SessionMatcher.findMatch(
            runDate: today,
            distanceKm: 10,
            duration: 3600,
            candidates: []
        )
        #expect(result == nil)
    }

    @Test("All candidates on different days with no near-day fallback returns nil")
    func differentDaysNoFallback() {
        let farAway = makeSession(
            date: calendar.date(byAdding: .day, value: -5, to: today)!
        )
        let result = SessionMatcher.findMatch(
            runDate: today,
            distanceKm: 15,
            duration: 5400,
            candidates: [farAway]
        )
        #expect(result == nil)
    }

    @Test("Distance too different with multiple candidates returns nil")
    func distanceTooFar() {
        let session1 = makeSession(distanceKm: 5, duration: 1800)
        let session2 = makeSession(distanceKm: 8, duration: 2800)

        let result = SessionMatcher.findMatch(
            runDate: today,
            distanceKm: 50,
            duration: 18000,
            candidates: [session1, session2]
        )

        #expect(result == nil)
    }

    // MARK: - Near-Day Fallback

    @Test("±1 day fallback works with reduced confidence")
    func nearDayFallback() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let session = makeSession(date: yesterday, distanceKm: 15, duration: 5400)

        let result = SessionMatcher.findMatch(
            runDate: today,
            distanceKm: 15,
            duration: 5400,
            candidates: [session]
        )

        #expect(result != nil)
        #expect(result?.session.id == session.id)
        #expect(result?.confidence == 0.7)
    }

    @Test("±1 day confidence is capped at 0.7")
    func nearDayConfidenceCapped() {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let session = makeSession(date: tomorrow, distanceKm: 10, duration: 3600)

        let result = SessionMatcher.findMatch(
            runDate: today,
            distanceKm: 10,
            duration: 3600,
            candidates: [session]
        )

        #expect(result != nil)
        #expect(result!.confidence <= 0.7)
    }

    @Test("Same-day match preferred over near-day match")
    func sameDayPreferred() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let todaySession = makeSession(date: today, distanceKm: 15, duration: 5400)
        let yesterdaySession = makeSession(date: yesterday, distanceKm: 15, duration: 5400)

        let result = SessionMatcher.findMatch(
            runDate: today,
            distanceKm: 15,
            duration: 5400,
            candidates: [yesterdaySession, todaySession]
        )

        #expect(result?.session.id == todaySession.id)
        #expect(result!.confidence > 0.7)
    }
}
