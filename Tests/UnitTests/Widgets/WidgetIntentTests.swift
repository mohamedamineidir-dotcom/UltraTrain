import Foundation
import Testing
@testable import UltraTrain

/// Tests for the shared data contracts that widget intents rely on.
/// The AppIntent types themselves live in the widget extension target, but
/// their data flows through WidgetPendingAction, WidgetDataKeys, and
/// WidgetDataReader — all of which are in the main target.
@Suite("Widget Intent Data Contract Tests", .serialized)
struct WidgetIntentTests {

    private let sharedDefaults = UserDefaults(suiteName: WidgetDataKeys.suiteName)!

    private func cleanup() {
        sharedDefaults.removeObject(forKey: WidgetDataKeys.pendingAction)
        sharedDefaults.removeObject(forKey: WidgetDataKeys.deepLink)
        sharedDefaults.removeObject(forKey: WidgetDataKeys.runCommand)
    }

    // MARK: - Pending Action Contract (MarkSessionComplete / SkipSession Intents)

    @Test("WidgetPendingAction written to UserDefaults is readable by WidgetDataReader")
    func pendingActionWriteReadContract() {
        cleanup()

        let sessionId = UUID()
        let action = WidgetPendingAction(
            sessionId: sessionId,
            action: "complete",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let encoded = try! JSONEncoder().encode(action)
        sharedDefaults.set(encoded, forKey: WidgetDataKeys.pendingAction)

        let read = WidgetDataReader.readPendingAction()
        #expect(read != nil)
        #expect(read?.sessionId == sessionId)
        #expect(read?.action == "complete")

        cleanup()
    }

    @Test("WidgetPendingAction skip action follows the same data contract")
    func pendingActionSkipContract() {
        cleanup()

        let sessionId = UUID()
        let action = WidgetPendingAction(
            sessionId: sessionId,
            action: "skip",
            timestamp: .now
        )
        let encoded = try! JSONEncoder().encode(action)
        sharedDefaults.set(encoded, forKey: WidgetDataKeys.pendingAction)

        let read = WidgetDataReader.readPendingAction()
        #expect(read?.action == "skip")
        #expect(read?.sessionId == sessionId)

        cleanup()
    }

    @Test("clearPendingAction removes the action so it is not processed again")
    func clearPendingActionRemovesData() {
        cleanup()

        let action = WidgetPendingAction(
            sessionId: UUID(),
            action: "complete",
            timestamp: .now
        )
        let encoded = try! JSONEncoder().encode(action)
        sharedDefaults.set(encoded, forKey: WidgetDataKeys.pendingAction)

        #expect(WidgetDataReader.readPendingAction() != nil)

        WidgetDataReader.clearPendingAction()

        #expect(WidgetDataReader.readPendingAction() == nil)

        cleanup()
    }

    // MARK: - Deep Link Contract (StartRun / Navigation Intents)

    @Test("Deep link written by StartRunIntent pattern is readable from UserDefaults")
    func deepLinkWriteReadContract() {
        cleanup()

        // Simulate what StartRunIntent.perform() does
        sharedDefaults.set("run", forKey: WidgetDataKeys.deepLink)

        let value = sharedDefaults.string(forKey: WidgetDataKeys.deepLink)
        #expect(value == "run")

        cleanup()
    }

    // MARK: - Run Command Contract (PauseRun / ResumeRun Intents)

    @Test("Run command written by intent is readable via WidgetDataReader")
    func runCommandWriteReadContract() {
        cleanup()

        // Simulate what PauseRunIntent.perform() and ResumeRunIntent.perform() do
        sharedDefaults.set("pause", forKey: WidgetDataKeys.runCommand)
        #expect(WidgetDataReader.readRunCommand() == "pause")

        sharedDefaults.set("resume", forKey: WidgetDataKeys.runCommand)
        #expect(WidgetDataReader.readRunCommand() == "resume")

        WidgetDataReader.clearRunCommand()
        #expect(WidgetDataReader.readRunCommand() == nil)

        cleanup()
    }
}
