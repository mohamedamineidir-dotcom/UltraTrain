import Foundation
@testable import UltraTrain

@MainActor
final class MockVoiceCoachingService: VoiceCoachingServiceProtocol {
    var spokenCues: [VoiceCue] = []
    var stopCallCount = 0
    var isSpeaking = false

    func speak(_ cue: VoiceCue) {
        spokenCues.append(cue)
    }

    func stop() {
        stopCallCount += 1
    }
}
