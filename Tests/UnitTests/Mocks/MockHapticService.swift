import Foundation
@testable import UltraTrain

@MainActor
final class MockHapticService: HapticServiceProtocol {
    var prepareHapticsCalled = false
    var playNutritionAlertCalled = false
    var playSuccessCalled = false
    var playErrorCalled = false
    var playSelectionCalled = false
    var playButtonTapCalled = false
    var playPacingAlertMinorCalled = false
    var playPacingAlertMajorCalled = false
    var playIntervalStartCalled = false
    var playIntervalEndCalled = false
    var playIntervalCountdownCalled = false
    var playSOSAlertCalled = false
    var playFallDetectedAlertCalled = false

    func prepareHaptics() { prepareHapticsCalled = true }
    func playNutritionAlert() { playNutritionAlertCalled = true }
    func playSuccess() { playSuccessCalled = true }
    func playError() { playErrorCalled = true }
    func playSelection() { playSelectionCalled = true }
    func playButtonTap() { playButtonTapCalled = true }
    func playPacingAlertMinor() { playPacingAlertMinorCalled = true }
    func playPacingAlertMajor() { playPacingAlertMajorCalled = true }
    func playIntervalStart() { playIntervalStartCalled = true }
    func playIntervalEnd() { playIntervalEndCalled = true }
    func playIntervalCountdown() { playIntervalCountdownCalled = true }
    func playSOSAlert() { playSOSAlertCalled = true }
    func playFallDetectedAlert() { playFallDetectedAlertCalled = true }
}
