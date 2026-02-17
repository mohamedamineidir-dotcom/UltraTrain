import Foundation
@testable import UltraTrain

@MainActor
final class MockLiveActivityService: LiveActivityServiceProtocol {
    var startCallCount = 0
    var updateCallCount = 0
    var endCallCount = 0
    var lastState: RunActivityAttributes.ContentState?
    var lastAttributes: RunActivityAttributes?

    var isActivityActive: Bool {
        startCallCount > endCallCount
    }

    func startActivity(attributes: RunActivityAttributes, state: RunActivityAttributes.ContentState) {
        startCallCount += 1
        lastAttributes = attributes
        lastState = state
    }

    func updateActivity(state: RunActivityAttributes.ContentState) {
        updateCallCount += 1
        lastState = state
    }

    func endActivity(state: RunActivityAttributes.ContentState) {
        endCallCount += 1
        lastState = state
    }
}
