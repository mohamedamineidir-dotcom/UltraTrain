import Foundation
import os

@Observable
@MainActor
final class VoiceCoachingHandler {

    // MARK: - Dependencies

    private let voiceService: any VoiceCoachingServiceProtocol
    var config: VoiceCoachingConfig

    // MARK: - Tracking State

    private var lastAnnouncedDistanceKm: Double = 0
    private var lastAnnouncedTimeMinutes: Int = 0
    private var lastZoneName: String?

    // MARK: - Init

    init(voiceService: any VoiceCoachingServiceProtocol, config: VoiceCoachingConfig) {
        self.voiceService = voiceService
        self.config = config
    }

    // MARK: - Tick (called every second from ActiveRunViewModel)

    func tick(snapshot: VoiceCueBuilder.RunSnapshot) {
        guard config.enabled else { return }
        checkDistanceSplit(snapshot)
        checkTimeSplit(snapshot)
        checkHRZoneChange(snapshot)
    }

    // MARK: - Event-Based Announcements

    func announceNutritionReminder() {
        guard config.enabled, config.announceNutritionReminders else { return }
        let cue = VoiceCueBuilder.nutritionReminderCue()
        voiceService.speak(cue)
    }

    func announceCheckpointCrossing(name: String, timeDelta: TimeInterval?) {
        guard config.enabled, config.announceCheckpoints else { return }
        let cue = VoiceCueBuilder.checkpointCue(name: name, timeDelta: timeDelta)
        voiceService.speak(cue)
    }

    func announcePacingAlert(message: String) {
        guard config.enabled, config.announcePacingAlerts else { return }
        let cue = VoiceCueBuilder.pacingAlertCue(message: message)
        voiceService.speak(cue)
    }

    func announceZoneDrift(currentZone: Int, targetZone: Int, duration: TimeInterval) {
        guard config.enabled, config.announceZoneDriftAlerts else { return }
        let cue = VoiceCueBuilder.zoneDriftCue(
            currentZone: currentZone, targetZone: targetZone, duration: duration
        )
        voiceService.speak(cue)
    }

    func announceRunState(_ type: VoiceCueType) {
        guard config.enabled else { return }
        let cue = VoiceCueBuilder.runStateCue(type: type)
        voiceService.speak(cue)
    }

    func announceIntervalTransition(
        phaseType: IntervalPhaseType,
        intervalNumber: Int?,
        totalIntervals: Int?
    ) {
        guard config.enabled, config.announceIntervalTransitions else { return }
        let cue = VoiceCueBuilder.intervalPhaseStartCue(
            phaseType: phaseType,
            intervalNumber: intervalNumber,
            totalIntervals: totalIntervals
        )
        voiceService.speak(cue)
    }

    func announceIntervalCountdown(seconds: Int) {
        guard config.enabled, config.announceIntervalTransitions else { return }
        let cue = VoiceCueBuilder.intervalCountdownCue(seconds: seconds)
        voiceService.speak(cue)
    }

    func announceIntervalComplete(totalWorkTime: TimeInterval, totalIntervals: Int) {
        guard config.enabled, config.announceIntervalTransitions else { return }
        let cue = VoiceCueBuilder.intervalWorkoutCompleteCue(
            totalWorkTime: totalWorkTime, totalIntervals: totalIntervals
        )
        voiceService.speak(cue)
    }

    func stopSpeaking() {
        voiceService.stop()
    }

    // MARK: - Private — Split Detection

    private func checkDistanceSplit(_ snapshot: VoiceCueBuilder.RunSnapshot) {
        guard config.announceDistanceSplits else { return }
        let splitKm = AppConfiguration.VoiceCoaching.distanceSplitKm
        let unit: UnitPreference = snapshot.isMetric ? .metric : .imperial
        let currentValue = UnitFormatter.distanceValue(snapshot.distanceKm, unit: unit)
        let lastValue = UnitFormatter.distanceValue(lastAnnouncedDistanceKm, unit: unit)

        let currentSplit = Int(currentValue / splitKm)
        let lastSplit = Int(lastValue / splitKm)

        if currentSplit > lastSplit && currentSplit > 0 {
            lastAnnouncedDistanceKm = snapshot.distanceKm
            let cue = VoiceCueBuilder.distanceSplitCue(snapshot: snapshot)
            voiceService.speak(cue)
            Logger.voiceCoaching.info("Distance split announced at \(snapshot.distanceKm) km")
        }
    }

    private func checkTimeSplit(_ snapshot: VoiceCueBuilder.RunSnapshot) {
        guard config.announceTimeSplits else { return }
        let intervalMinutes = config.timeSplitIntervalMinutes
        guard intervalMinutes > 0 else { return }

        let currentMinute = Int(snapshot.elapsedTime / 60)
        let currentSplit = currentMinute / intervalMinutes

        if currentSplit > lastAnnouncedTimeMinutes && currentSplit > 0 {
            lastAnnouncedTimeMinutes = currentSplit
            let cue = VoiceCueBuilder.timeSplitCue(snapshot: snapshot)
            voiceService.speak(cue)
            Logger.voiceCoaching.info("Time split announced at \(currentMinute) min")
        }
    }

    private func checkHRZoneChange(_ snapshot: VoiceCueBuilder.RunSnapshot) {
        guard config.announceHRZoneChanges else { return }
        guard let currentZone = snapshot.currentZoneName else { return }

        if let previousZone = lastZoneName, previousZone != currentZone {
            let cue = VoiceCueBuilder.heartRateZoneChangeCue(snapshot: snapshot)
            voiceService.speak(cue)
            Logger.voiceCoaching.info("HR zone change announced: \(previousZone) → \(currentZone)")
        }
        lastZoneName = currentZone
    }
}
