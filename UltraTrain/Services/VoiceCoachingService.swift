import AVFoundation
import os

@MainActor
protocol VoiceCoachingServiceProtocol: Sendable {
    func speak(_ cue: VoiceCue)
    func stop()
    var isSpeaking: Bool { get }
}

@MainActor
final class VoiceCoachingService: NSObject, VoiceCoachingServiceProtocol {

    private let synthesizer = AVSpeechSynthesizer()
    private var queue: [VoiceCue] = []
    private var isSpeakingCue = false
    private var speechRate: Float

    private static let maxQueueSize = AppConfiguration.VoiceCoaching.maxQueueSize

    var isSpeaking: Bool { isSpeakingCue }

    init(speechRate: Float = AppConfiguration.VoiceCoaching.defaultSpeechRate) {
        self.speechRate = speechRate
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }

    func speak(_ cue: VoiceCue) {
        if isSpeakingCue {
            if queue.count >= Self.maxQueueSize {
                dropLowestPriority()
            }
            queue.append(cue)
            Logger.voiceCoaching.debug("Queued cue: \(cue.type.rawValue)")
            return
        }
        speakNow(cue)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        queue.removeAll()
        isSpeakingCue = false
        deactivateAudioSession()
    }

    // MARK: - Private

    private func speakNow(_ cue: VoiceCue) {
        isSpeakingCue = true
        activateAudioSession()
        let utterance = AVSpeechUtterance(string: cue.message)
        utterance.rate = speechRate
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1
        synthesizer.speak(utterance)
        Logger.voiceCoaching.info("Speaking: \(cue.type.rawValue)")
    }

    private func processQueue() {
        guard !queue.isEmpty else {
            isSpeakingCue = false
            deactivateAudioSession()
            return
        }
        let next = queue.removeFirst()
        speakNow(next)
    }

    private func dropLowestPriority() {
        guard let minPriority = queue.min(by: { $0.priority < $1.priority })?.priority,
              let index = queue.firstIndex(where: { $0.priority == minPriority }) else { return }
        let dropped = queue.remove(at: index)
        Logger.voiceCoaching.debug("Dropped low-priority cue: \(dropped.type.rawValue)")
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
            Logger.voiceCoaching.info("Audio session configured for voice coaching")
        } catch {
            Logger.voiceCoaching.error("Failed to configure audio session: \(error)")
        }
    }

    private func activateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            Logger.voiceCoaching.error("Failed to activate audio session: \(error)")
        }
    }

    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            Logger.voiceCoaching.debug("Audio session deactivation: \(error)")
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension VoiceCoachingService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            self.processQueue()
        }
    }
}
