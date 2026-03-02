import Foundation
import Testing
@testable import UltraTrain

@Suite("VoiceCoachingService Tests")
struct VoiceCoachingServiceTests {

    // These tests use MockVoiceCoachingService since the real service
    // requires AVSpeechSynthesizer which is unavailable in unit tests.

    private func makeCue(
        type: VoiceCueType = .distanceSplit,
        message: String = "1 kilometer",
        priority: VoiceCuePriority = .medium
    ) -> VoiceCue {
        VoiceCue(type: type, message: message, priority: priority)
    }

    @Test("speak records the cue")
    @MainActor
    func speakRecordsCue() {
        let service = MockVoiceCoachingService()

        let cue = makeCue(type: .distanceSplit, message: "1 km complete")
        service.speak(cue)

        #expect(service.spokenCues.count == 1)
        #expect(service.spokenCues[0].type == .distanceSplit)
        #expect(service.spokenCues[0].message == "1 km complete")
    }

    @Test("speak records multiple cues in order")
    @MainActor
    func speakRecordsMultipleCues() {
        let service = MockVoiceCoachingService()

        let cue1 = makeCue(type: .distanceSplit, message: "1 km")
        let cue2 = makeCue(type: .nutritionReminder, message: "Time to eat")
        let cue3 = makeCue(type: .heartRateZoneChange, message: "Zone 3")

        service.speak(cue1)
        service.speak(cue2)
        service.speak(cue3)

        #expect(service.spokenCues.count == 3)
        #expect(service.spokenCues[0].type == .distanceSplit)
        #expect(service.spokenCues[1].type == .nutritionReminder)
        #expect(service.spokenCues[2].type == .heartRateZoneChange)
    }

    @Test("stop increments call count")
    @MainActor
    func stopIncrementsCount() {
        let service = MockVoiceCoachingService()

        service.stop()
        service.stop()

        #expect(service.stopCallCount == 2)
    }

    @Test("isSpeaking is false by default")
    @MainActor
    func isSpeakingDefaultFalse() {
        let service = MockVoiceCoachingService()

        #expect(!service.isSpeaking)
    }

    @Test("VoiceCue priority ordering is correct")
    func voiceCuePriorityOrdering() {
        let low = VoiceCuePriority.low
        let medium = VoiceCuePriority.medium
        let high = VoiceCuePriority.high

        #expect(low < medium)
        #expect(medium < high)
        #expect(low < high)
    }

    @Test("VoiceCue equality works correctly")
    func voiceCueEquality() {
        let cue1 = VoiceCue(type: .distanceSplit, message: "test", priority: .high)
        let cue2 = VoiceCue(type: .distanceSplit, message: "test", priority: .high)
        let cue3 = VoiceCue(type: .nutritionReminder, message: "test", priority: .high)

        #expect(cue1 == cue2)
        #expect(cue1 != cue3)
    }
}
