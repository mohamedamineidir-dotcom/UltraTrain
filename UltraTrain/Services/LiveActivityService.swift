import ActivityKit
import Foundation
import os

@MainActor
protocol LiveActivityServiceProtocol: Sendable {
    func startActivity(attributes: RunActivityAttributes, state: RunActivityAttributes.ContentState)
    func updateActivity(state: RunActivityAttributes.ContentState)
    func endActivity(state: RunActivityAttributes.ContentState)
    var isActivityActive: Bool { get }
}

@MainActor
final class LiveActivityService: LiveActivityServiceProtocol {

    // MARK: - State

    private var currentActivity: Activity<RunActivityAttributes>?

    var isActivityActive: Bool {
        currentActivity != nil
    }

    // MARK: - Start

    func startActivity(attributes: RunActivityAttributes, state: RunActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            Logger.liveActivity.warning("Live Activities not enabled by user")
            return
        }

        // End any stale activity first
        if currentActivity != nil {
            endActivity(state: state)
        }

        let content = ActivityContent(state: state, staleDate: nil)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            Logger.liveActivity.info("Live Activity started")
        } catch {
            Logger.liveActivity.error("Failed to start Live Activity: \(error)")
        }
    }

    // MARK: - Update

    func updateActivity(state: RunActivityAttributes.ContentState) {
        guard let activity = currentActivity else { return }

        let content = ActivityContent(state: state, staleDate: nil)

        Task {
            await activity.update(content)
        }
    }

    // MARK: - End

    func endActivity(state: RunActivityAttributes.ContentState) {
        guard let activity = currentActivity else { return }

        let content = ActivityContent(state: state, staleDate: nil)

        Task {
            await activity.end(content, dismissalPolicy: .after(.now + 300))
            Logger.liveActivity.info("Live Activity ended")
        }

        currentActivity = nil
    }
}
