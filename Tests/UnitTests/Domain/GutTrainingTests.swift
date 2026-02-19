import Foundation
import Testing
@testable import UltraTrain

@Suite("Gut Training Tests")
struct GutTrainingTests {

    private func makeSession(
        type: SessionType = .longRun,
        duration: TimeInterval = 7200
    ) -> TrainingSession {
        TrainingSession(
            id: UUID(),
            date: .now,
            type: type,
            plannedDistanceKm: 20,
            plannedElevationGainM: 500,
            plannedDuration: duration,
            intensity: .moderate,
            description: "Test session",
            nutritionNotes: nil,
            isCompleted: false,
            isSkipped: false,
            linkedRunId: nil
        )
    }

    @Test("Long run >= 2h is gut training recommended")
    func longRunGutTraining() {
        let session = makeSession(type: .longRun, duration: 7200)
        #expect(session.isGutTrainingRecommended == true)
    }

    @Test("Back-to-back >= 2h is gut training recommended")
    func backToBackGutTraining() {
        let session = makeSession(type: .backToBack, duration: 9000)
        #expect(session.isGutTrainingRecommended == true)
    }

    @Test("Long run < 2h is not gut training recommended")
    func shortLongRunNotGutTraining() {
        let session = makeSession(type: .longRun, duration: 5400)
        #expect(session.isGutTrainingRecommended == false)
    }

    @Test("Tempo >= 2h is not gut training recommended")
    func tempoNotGutTraining() {
        let session = makeSession(type: .tempo, duration: 7200)
        #expect(session.isGutTrainingRecommended == false)
    }

    @Test("Recovery session is not gut training recommended")
    func recoveryNotGutTraining() {
        let session = makeSession(type: .recovery, duration: 3600)
        #expect(session.isGutTrainingRecommended == false)
    }
}
