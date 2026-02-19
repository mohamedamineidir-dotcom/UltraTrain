import Foundation
import Testing
@testable import UltraTrain

@Suite("GradientCategory Tests")
struct GradientCategoryTests {

    @Test("Steep down for gradient below -15")
    func steepDown() {
        #expect(GradientCategory.from(gradient: -20) == .steepDown)
        #expect(GradientCategory.from(gradient: -15.1) == .steepDown)
    }

    @Test("Moderate down for gradient -15 to -5")
    func moderateDown() {
        #expect(GradientCategory.from(gradient: -15) == .moderateDown)
        #expect(GradientCategory.from(gradient: -10) == .moderateDown)
        #expect(GradientCategory.from(gradient: -5.1) == .moderateDown)
    }

    @Test("Flat for gradient -5 to 5")
    func flat() {
        #expect(GradientCategory.from(gradient: -5) == .flat)
        #expect(GradientCategory.from(gradient: 0) == .flat)
        #expect(GradientCategory.from(gradient: 4.9) == .flat)
    }

    @Test("Moderate up for gradient 5 to 15")
    func moderateUp() {
        #expect(GradientCategory.from(gradient: 5) == .moderateUp)
        #expect(GradientCategory.from(gradient: 10) == .moderateUp)
        #expect(GradientCategory.from(gradient: 14.9) == .moderateUp)
    }

    @Test("Steep up for gradient 15 and above")
    func steepUp() {
        #expect(GradientCategory.from(gradient: 15) == .steepUp)
        #expect(GradientCategory.from(gradient: 25) == .steepUp)
    }

    @Test("All cases are five categories")
    func allCases() {
        #expect(GradientCategory.allCases.count == 5)
    }
}
