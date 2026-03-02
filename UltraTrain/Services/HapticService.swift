import AudioToolbox
import os
import UIKit

@MainActor
protocol HapticServiceProtocol: Sendable {
    func prepareHaptics()
    func playNutritionAlert()
    func playSuccess()
    func playError()
    func playSelection()
    func playButtonTap()
    func playPacingAlertMinor()
    func playPacingAlertMajor()
    func playIntervalStart()
    func playIntervalEnd()
    func playIntervalCountdown()
    func playSOSAlert()
    func playFallDetectedAlert()
}

@MainActor
final class HapticService: HapticServiceProtocol {

    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let softImpactGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    func prepareHaptics() {
        heavyImpactGenerator.prepare()
        softImpactGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    private var cachedSoundIDs: [String: SystemSoundID] = [:]

    private func playBundledSound(named filename: String) {
        if let cached = cachedSoundIDs[filename] {
            AudioServicesPlaySystemSound(cached)
            return
        }
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
            // Fall back to system sound if custom file not found
            AudioServicesPlaySystemSound(1304)
            return
        }
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        cachedSoundIDs[filename] = soundID
        AudioServicesPlaySystemSound(soundID)
    }

    func playNutritionAlert() {
        heavyImpactGenerator.impactOccurred()
        playBundledSound(named: NotificationCategory.nutrition.customSoundFilename)
        Logger.haptic.info("Nutrition alert played (haptic + custom sound)")
    }

    func playSuccess() {
        notificationGenerator.notificationOccurred(.success)
        Logger.haptic.info("Success haptic played")
    }

    func playError() {
        notificationGenerator.notificationOccurred(.error)
        Logger.haptic.info("Error haptic played")
    }

    func playSelection() {
        selectionGenerator.selectionChanged()
    }

    func playButtonTap() {
        softImpactGenerator.impactOccurred()
    }

    func playPacingAlertMinor() {
        selectionGenerator.selectionChanged()
    }

    func playPacingAlertMajor() {
        heavyImpactGenerator.impactOccurred()
    }

    func playIntervalStart() {
        heavyImpactGenerator.impactOccurred()
        playBundledSound(named: NotificationCategory.training.customSoundFilename)
        Logger.haptic.info("Interval start haptic played")
    }

    func playIntervalEnd() {
        notificationGenerator.notificationOccurred(.success)
        Logger.haptic.info("Interval end haptic played")
    }

    func playIntervalCountdown() {
        softImpactGenerator.impactOccurred()
    }

    func playSOSAlert() {
        notificationGenerator.notificationOccurred(.error)
        AudioServicesPlaySystemSound(1005)
        Logger.haptic.info("SOS alert haptic played")
    }

    func playFallDetectedAlert() {
        heavyImpactGenerator.impactOccurred()
        AudioServicesPlaySystemSound(1005)
        Logger.haptic.info("Fall detected alert haptic played")
    }
}
