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

    func prepareHaptics() { prepareHapticsCalled = true }
    func playNutritionAlert() { playNutritionAlertCalled = true }
    func playSuccess() { playSuccessCalled = true }
    func playError() { playErrorCalled = true }
    func playSelection() { playSelectionCalled = true }
    func playButtonTap() { playButtonTapCalled = true }
    func playPacingAlertMinor() { playPacingAlertMinorCalled = true }
    func playPacingAlertMajor() { playPacingAlertMajorCalled = true }
}
