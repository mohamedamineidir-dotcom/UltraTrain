import Foundation
import Testing
@testable import UltraTrain

@Suite("Finish Estimate Tests")
struct FinishEstimateTests {

    @Test("Duration formatting")
    func formatDuration() {
        let formatted = FinishEstimate.formatDuration(36000) // 10 hours
        #expect(formatted == "10h00")
    }

    @Test("Duration formatting with minutes")
    func formatDurationWithMinutes() {
        let formatted = FinishEstimate.formatDuration(41400) // 11h30
        #expect(formatted == "11h30")
    }
}
