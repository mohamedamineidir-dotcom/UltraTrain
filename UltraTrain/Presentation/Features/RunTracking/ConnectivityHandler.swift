import ActivityKit
import Foundation
import os

@Observable
@MainActor
final class ConnectivityHandler {

    // MARK: - Dependencies

    private let connectivityService: PhoneConnectivityService?
    private let liveActivityService: any LiveActivityServiceProtocol
    private let stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)?
    private let stravaAutoUploadEnabled: Bool

    // MARK: - State

    var stravaUploadStatus: StravaUploadStatus = .idle
    private var lastLiveActivityUpdate: TimeInterval = 0

    // MARK: - Context

    struct RunSnapshot: Sendable {
        let runState: RunState
        let elapsedTime: TimeInterval
        let distanceKm: Double
        let currentPace: String
        let currentHeartRate: Int?
        let elevationGainM: Double
        let formattedTime: String
        let formattedDistance: String
        let formattedElevation: String
        let isAutoPaused: Bool
        let activeReminderMessage: String?
        let activeReminderType: String?
        let linkedSessionName: String?

        // Race mode
        let nextCheckpointName: String?
        let distanceToCheckpointKm: Double?
        let projectedFinishTime: String?
        let timeDeltaSeconds: Double?

        // Nutrition
        let activeNutritionReminder: String?
    }

    // MARK: - Init

    init(
        connectivityService: PhoneConnectivityService?,
        liveActivityService: any LiveActivityServiceProtocol,
        stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)?,
        stravaAutoUploadEnabled: Bool
    ) {
        self.connectivityService = connectivityService
        self.liveActivityService = liveActivityService
        self.stravaUploadQueueService = stravaUploadQueueService
        self.stravaAutoUploadEnabled = stravaAutoUploadEnabled
    }

    // MARK: - Watch

    func setupCommandHandler(
        onPause: @escaping @MainActor () -> Void,
        onResume: @escaping @MainActor () -> Void,
        onStop: @escaping @MainActor () -> Void,
        onDismissReminder: @escaping @MainActor () -> Void
    ) {
        connectivityService?.commandHandler = { command in
            switch command {
            case .pause: onPause()
            case .resume: onResume()
            case .stop: onStop()
            case .dismissReminder: onDismissReminder()
            }
        }
    }

    func sendWatchUpdate(snapshot: RunSnapshot) {
        connectivityService?.sendRunUpdate(buildWatchRunData(snapshot: snapshot))
    }

    // MARK: - Live Activity

    func startLiveActivity(snapshot: RunSnapshot) {
        let attributes = RunActivityAttributes(
            startTime: Date.now,
            linkedSessionName: snapshot.linkedSessionName
        )
        liveActivityService.startActivity(
            attributes: attributes,
            state: buildLiveActivityState(snapshot: snapshot)
        )
    }

    func updateLiveActivityIfNeeded(snapshot: RunSnapshot) {
        let now = snapshot.elapsedTime
        guard now - lastLiveActivityUpdate >= AppConfiguration.LiveActivity.updateIntervalSeconds else { return }
        lastLiveActivityUpdate = now
        liveActivityService.updateActivity(state: buildLiveActivityState(snapshot: snapshot))
    }

    func updateLiveActivityImmediately(snapshot: RunSnapshot) {
        lastLiveActivityUpdate = snapshot.elapsedTime
        liveActivityService.updateActivity(state: buildLiveActivityState(snapshot: snapshot))
    }

    func endLiveActivity(snapshot: RunSnapshot) {
        liveActivityService.endActivity(state: buildLiveActivityState(snapshot: snapshot))
    }

    // MARK: - Strava

    func autoUploadToStrava(runId: UUID, hasTrack: Bool) {
        guard stravaAutoUploadEnabled,
              let queueService = stravaUploadQueueService,
              hasTrack else { return }
        stravaUploadStatus = .uploading
        Task { [weak self] in
            do {
                try await queueService.enqueueUpload(runId: runId)
                await queueService.processQueue()
                if let status = await queueService.getQueueStatus(forRunId: runId),
                   status == .completed {
                    self?.stravaUploadStatus = .success(activityId: 0)
                } else {
                    self?.stravaUploadStatus = .idle
                }
                Logger.strava.info("Auto-upload queued for run \(runId)")
            } catch {
                self?.stravaUploadStatus = .failed(reason: error.localizedDescription)
                Logger.strava.error("Auto-upload to Strava failed: \(error)")
            }
        }
    }

    func manualUploadToStrava(runId: UUID) async {
        guard let queueService = stravaUploadQueueService else { return }
        stravaUploadStatus = .uploading
        do {
            try await queueService.enqueueUpload(runId: runId)
            await queueService.processQueue()
            if let status = await queueService.getQueueStatus(forRunId: runId),
               status == .completed {
                stravaUploadStatus = .success(activityId: 0)
            } else {
                stravaUploadStatus = .idle
            }
        } catch {
            stravaUploadStatus = .failed(reason: error.localizedDescription)
            Logger.strava.error("Strava upload failed: \(error)")
        }
    }

    // MARK: - Private

    private func buildLiveActivityState(snapshot: RunSnapshot) -> RunActivityAttributes.ContentState {
        let stateString: String = switch snapshot.runState {
        case .notStarted: "notStarted"
        case .running: "running"
        case .paused: snapshot.isAutoPaused ? "autoPaused" : "paused"
        case .finished: "finished"
        }

        let isPaused = snapshot.runState == .paused || snapshot.runState == .finished
        let timerStartDate = isPaused ? Date.now : Date.now.addingTimeInterval(-snapshot.elapsedTime)

        return RunActivityAttributes.ContentState(
            elapsedTime: snapshot.elapsedTime,
            distanceKm: snapshot.distanceKm,
            currentHeartRate: snapshot.currentHeartRate,
            elevationGainM: snapshot.elevationGainM,
            runState: stateString,
            isAutoPaused: snapshot.isAutoPaused,
            formattedDistance: snapshot.formattedDistance,
            formattedElevation: snapshot.formattedElevation,
            formattedPace: snapshot.currentPace,
            timerStartDate: timerStartDate,
            isPaused: isPaused,
            nextCheckpointName: snapshot.nextCheckpointName,
            distanceToCheckpointKm: snapshot.distanceToCheckpointKm,
            projectedFinishTime: snapshot.projectedFinishTime,
            timeDeltaSeconds: snapshot.timeDeltaSeconds,
            activeNutritionReminder: snapshot.activeNutritionReminder
        )
    }

    private func buildWatchRunData(snapshot: RunSnapshot) -> WatchRunData {
        let stateString: String = switch snapshot.runState {
        case .notStarted: "notStarted"
        case .running: "running"
        case .paused: snapshot.isAutoPaused ? "autoPaused" : "paused"
        case .finished: "finished"
        }

        return WatchRunData(
            runState: stateString,
            elapsedTime: snapshot.elapsedTime,
            distanceKm: snapshot.distanceKm,
            currentPace: snapshot.currentPace,
            currentHeartRate: snapshot.currentHeartRate,
            elevationGainM: snapshot.elevationGainM,
            formattedTime: snapshot.formattedTime,
            formattedDistance: snapshot.formattedDistance,
            formattedElevation: snapshot.formattedElevation,
            isAutoPaused: snapshot.isAutoPaused,
            activeReminderMessage: snapshot.activeReminderMessage,
            activeReminderType: snapshot.activeReminderType
        )
    }
}
