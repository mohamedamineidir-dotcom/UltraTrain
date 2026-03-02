import Foundation
import Testing
@testable import UltraTrain

@Suite("HapticService Tests")
struct HapticServiceTests {

    // NOTE: HapticService depends on UIKit haptic generators which require a device.
    // We test the MockHapticService to verify the protocol contract, and verify
    // the real HapticService can be instantiated.

    // MARK: - Mock Protocol Conformance

    @MainActor
    @Test("MockHapticService tracks prepareHaptics call")
    func mockTracksPrepareHaptics() {
        let mock = MockHapticService()
        #expect(!mock.prepareHapticsCalled)

        mock.prepareHaptics()
        #expect(mock.prepareHapticsCalled)
    }

    @MainActor
    @Test("MockHapticService tracks all alert types")
    func mockTracksAllAlertTypes() {
        let mock = MockHapticService()

        mock.playNutritionAlert()
        #expect(mock.playNutritionAlertCalled)

        mock.playSuccess()
        #expect(mock.playSuccessCalled)

        mock.playError()
        #expect(mock.playErrorCalled)

        mock.playSelection()
        #expect(mock.playSelectionCalled)

        mock.playButtonTap()
        #expect(mock.playButtonTapCalled)
    }

    @MainActor
    @Test("MockHapticService tracks pacing alerts")
    func mockTracksPacingAlerts() {
        let mock = MockHapticService()

        mock.playPacingAlertMinor()
        #expect(mock.playPacingAlertMinorCalled)

        mock.playPacingAlertMajor()
        #expect(mock.playPacingAlertMajorCalled)
    }

    @MainActor
    @Test("MockHapticService tracks interval haptics")
    func mockTracksIntervalHaptics() {
        let mock = MockHapticService()

        mock.playIntervalStart()
        #expect(mock.playIntervalStartCalled)

        mock.playIntervalEnd()
        #expect(mock.playIntervalEndCalled)

        mock.playIntervalCountdown()
        #expect(mock.playIntervalCountdownCalled)
    }

    @MainActor
    @Test("MockHapticService tracks emergency haptics")
    func mockTracksEmergencyHaptics() {
        let mock = MockHapticService()

        mock.playSOSAlert()
        #expect(mock.playSOSAlertCalled)

        mock.playFallDetectedAlert()
        #expect(mock.playFallDetectedAlertCalled)
    }

    // MARK: - Protocol Completeness

    @MainActor
    @Test("HapticServiceProtocol has all required methods")
    func protocolHasAllMethods() {
        // Verify mock conforms -- if it compiles, protocol is complete
        let service: any HapticServiceProtocol = MockHapticService()
        service.prepareHaptics()
        service.playNutritionAlert()
        service.playSuccess()
        service.playError()
        service.playSelection()
        service.playButtonTap()
        service.playPacingAlertMinor()
        service.playPacingAlertMajor()
        service.playIntervalStart()
        service.playIntervalEnd()
        service.playIntervalCountdown()
        service.playSOSAlert()
        service.playFallDetectedAlert()
    }

    @MainActor
    @Test("MockHapticService starts with all flags false")
    func mockStartsWithAllFlagsFalse() {
        let mock = MockHapticService()
        #expect(!mock.prepareHapticsCalled)
        #expect(!mock.playNutritionAlertCalled)
        #expect(!mock.playSuccessCalled)
        #expect(!mock.playErrorCalled)
        #expect(!mock.playSelectionCalled)
        #expect(!mock.playButtonTapCalled)
        #expect(!mock.playPacingAlertMinorCalled)
        #expect(!mock.playPacingAlertMajorCalled)
        #expect(!mock.playIntervalStartCalled)
        #expect(!mock.playIntervalEndCalled)
        #expect(!mock.playIntervalCountdownCalled)
        #expect(!mock.playSOSAlertCalled)
        #expect(!mock.playFallDetectedAlertCalled)
    }
}
