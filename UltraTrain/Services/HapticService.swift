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

    func playNutritionAlert() {
        heavyImpactGenerator.impactOccurred()

        // System sound 1304 is a subtle tri-tone alert
        AudioServicesPlaySystemSound(1304)

        Logger.haptic.info("Nutrition alert played (haptic + sound)")
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
        AudioServicesPlaySystemSound(1304)
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
