import Foundation
import Testing
@testable import UltraTrain

@Suite("Run Command Tests", .serialized)
struct RunCommandIntentsTests {

    private let defaults = UserDefaults(suiteName: WidgetDataKeys.suiteName)!

    private func cleanup() {
        defaults.removeObject(forKey: WidgetDataKeys.runCommand)
        defaults.removeObject(forKey: WidgetDataKeys.deepLink)
    }

    @Test("readRunCommand returns nil when no command is set")
    func readRunCommandReturnsNilWhenEmpty() {
        cleanup()
        #expect(WidgetDataReader.readRunCommand() == nil)
        cleanup()
    }

    @Test("readRunCommand reads a pause command from UserDefaults")
    func readRunCommandReadsPause() {
        cleanup()
        defaults.set("pause", forKey: WidgetDataKeys.runCommand)
        #expect(WidgetDataReader.readRunCommand() == "pause")
        cleanup()
    }

    @Test("readRunCommand reads a resume command from UserDefaults")
    func readRunCommandReadsResume() {
        cleanup()
        defaults.set("resume", forKey: WidgetDataKeys.runCommand)
        #expect(WidgetDataReader.readRunCommand() == "resume")
        cleanup()
    }

    @Test("clearRunCommand removes the stored command")
    func clearRunCommandRemovesValue() {
        cleanup()
        defaults.set("pause", forKey: WidgetDataKeys.runCommand)
        #expect(WidgetDataReader.readRunCommand() != nil)
        WidgetDataReader.clearRunCommand()
        #expect(WidgetDataReader.readRunCommand() == nil)
        cleanup()
    }

    @Test("readRunCommand and clearRunCommand round-trip")
    func roundTrip() {
        cleanup()
        defaults.set("resume", forKey: WidgetDataKeys.runCommand)
        let value = WidgetDataReader.readRunCommand()
        #expect(value == "resume")
        WidgetDataReader.clearRunCommand()
        #expect(WidgetDataReader.readRunCommand() == nil)
        cleanup()
    }

    @Test("runCommand key uses the expected constant value")
    func runCommandKeyValue() {
        #expect(WidgetDataKeys.runCommand == "widget.runCommand")
    }
}
