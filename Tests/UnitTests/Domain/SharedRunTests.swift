import Foundation
import Testing
@testable import UltraTrain

@Suite("SharedRun Model Tests")
struct SharedRunTests {

    private func makeSharedRun(
        likeCount: Int = 0,
        commentCount: Int = 0
    ) -> SharedRun {
        SharedRun(
            id: UUID(),
            sharedByProfileId: "sharer-1",
            sharedByDisplayName: "Ultra Runner",
            date: Date.now,
            distanceKm: 50.0,
            elevationGainM: 3000,
            elevationLossM: 2800,
            duration: 18000,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            notes: "Epic mountain run",
            sharedAt: Date.now,
            likeCount: likeCount,
            commentCount: commentCount
        )
    }

    @Test("SharedRun creation with all fields")
    func creationWithAllFields() {
        let run = makeSharedRun()

        #expect(run.sharedByProfileId == "sharer-1")
        #expect(run.sharedByDisplayName == "Ultra Runner")
        #expect(run.distanceKm == 50.0)
        #expect(run.elevationGainM == 3000)
        #expect(run.elevationLossM == 2800)
        #expect(run.duration == 18000)
        #expect(run.averagePaceSecondsPerKm == 360)
        #expect(run.notes == "Epic mountain run")
    }

    @Test("SharedRun default likeCount is 0")
    func defaultLikeCount() {
        let run = makeSharedRun(likeCount: 0)
        #expect(run.likeCount == 0)
    }

    @Test("SharedRun default commentCount is 0")
    func defaultCommentCount() {
        let run = makeSharedRun(commentCount: 0)
        #expect(run.commentCount == 0)
    }
}
