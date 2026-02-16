import AudioToolbox
import os
import UIKit

@MainActor
protocol HapticServiceProtocol: Sendable {
    func prepareHaptics()
    func playNutritionAlert()
}

@MainActor
final class HapticService: HapticServiceProtocol {

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)

    func prepareHaptics() {
        feedbackGenerator.prepare()
    }

    func playNutritionAlert() {
        feedbackGenerator.impactOccurred()

        // System sound 1304 is a subtle tri-tone alert
        AudioServicesPlaySystemSound(1304)

        Logger.haptic.info("Nutrition alert played (haptic + sound)")
    }
}
