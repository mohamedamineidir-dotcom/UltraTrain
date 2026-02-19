import Foundation
import Testing
@testable import UltraTrain

@Suite("StravaUploadQueueItem Tests")
struct StravaUploadQueueItemTests {

    private func makeItem(retryCount: Int = 0) -> StravaUploadQueueItem {
        StravaUploadQueueItem(
            id: UUID(),
            runId: UUID(),
            status: .pending,
            retryCount: retryCount,
            lastAttempt: nil,
            stravaActivityId: nil,
            errorMessage: nil,
            createdAt: Date.now
        )
    }

    // MARK: - hasReachedMaxRetries

    @Test("Has not reached max retries when count is 0")
    func hasNotReachedMaxRetriesAtZero() {
        let item = makeItem(retryCount: 0)
        #expect(item.hasReachedMaxRetries == false)
    }

    @Test("Has not reached max retries when count is 2")
    func hasNotReachedMaxRetriesAtTwo() {
        let item = makeItem(retryCount: 2)
        #expect(item.hasReachedMaxRetries == false)
    }

    @Test("Has reached max retries when count is 3")
    func hasReachedMaxRetriesAtThree() {
        let item = makeItem(retryCount: 3)
        #expect(item.hasReachedMaxRetries == true)
    }

    @Test("Has reached max retries when count exceeds 3")
    func hasReachedMaxRetriesAboveThree() {
        let item = makeItem(retryCount: 5)
        #expect(item.hasReachedMaxRetries == true)
    }

    // MARK: - nextRetryDelay

    @Test("First retry delay is 5 seconds")
    func firstRetryDelay() {
        let item = makeItem(retryCount: 0)
        #expect(item.nextRetryDelay == 5)
    }

    @Test("Second retry delay is 30 seconds")
    func secondRetryDelay() {
        let item = makeItem(retryCount: 1)
        #expect(item.nextRetryDelay == 30)
    }

    @Test("Third retry delay is 120 seconds")
    func thirdRetryDelay() {
        let item = makeItem(retryCount: 2)
        #expect(item.nextRetryDelay == 120)
    }

    @Test("Retry delay caps at 120 seconds for higher counts")
    func retryDelayCaps() {
        let item = makeItem(retryCount: 10)
        #expect(item.nextRetryDelay == 120)
    }
}
