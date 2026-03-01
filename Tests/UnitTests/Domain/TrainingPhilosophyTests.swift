import Foundation
import Testing
@testable import UltraTrain

@Suite("TrainingPhilosophy Tests")
struct TrainingPhilosophyTests {

    @Test("all cases have correct raw values")
    func rawValues() {
        #expect(TrainingPhilosophy.enjoyment.rawValue == "enjoyment")
        #expect(TrainingPhilosophy.balanced.rawValue == "balanced")
        #expect(TrainingPhilosophy.performance.rawValue == "performance")
    }

    @Test("allCases contains 3 values")
    func allCasesCount() {
        #expect(TrainingPhilosophy.allCases.count == 3)
    }

    @Test("displayName is non-empty for all cases")
    func displayNames() {
        for philosophy in TrainingPhilosophy.allCases {
            #expect(!philosophy.displayName.isEmpty)
        }
    }

    @Test("subtitle is non-empty for all cases")
    func subtitles() {
        for philosophy in TrainingPhilosophy.allCases {
            #expect(!philosophy.subtitle.isEmpty)
        }
    }

    @Test("iconName is non-empty for all cases")
    func iconNames() {
        for philosophy in TrainingPhilosophy.allCases {
            #expect(!philosophy.iconName.isEmpty)
        }
    }

    @Test("can be initialized from raw value")
    func initFromRawValue() {
        #expect(TrainingPhilosophy(rawValue: "enjoyment") == .enjoyment)
        #expect(TrainingPhilosophy(rawValue: "balanced") == .balanced)
        #expect(TrainingPhilosophy(rawValue: "performance") == .performance)
        #expect(TrainingPhilosophy(rawValue: "invalid") == nil)
    }
}
