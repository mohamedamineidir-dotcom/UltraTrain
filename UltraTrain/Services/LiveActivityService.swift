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

        // Check the SYSTEM-WIDE list, not just this instance's
        // `currentActivity` — a previous LiveActivityService instance
        // (e.g. from an ActiveRunViewModel that got silently replaced
        // rather than reused) can have started one this instance never
        // knew about. Leaving it running is how a run could end up with
        // two separate "RUNNING" Live Activities stacked on the Lock
        // Screen. Dismissed immediately (not the normal 300s-visible end)
        // since these are orphaned, not a real run finishing.
        let staleActivities = Activity<RunActivityAttributes>.activities
        if !staleActivities.isEmpty {
            for activity in staleActivities {
                Task { await activity.end(nil, dismissalPolicy: .immediate) }
            }
            Logger.liveActivity.info("Ended \(staleActivities.count) stale Live Activity(ies) before starting a new one")
        }
        currentActivity = nil

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
