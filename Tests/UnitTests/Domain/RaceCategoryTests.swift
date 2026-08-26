import Testing
@testable import UltraTrain

@Suite("RaceCategory Tests")
struct RaceCategoryTests {

    @Test("Trail category for short effective distances")
    func trailCategory() {
        #expect(RaceCategory.from(effectiveDistanceKm: 30) == .trail)
        #expect(RaceCategory.from(effectiveDistanceKm: 41) == .trail)
    }

    @Test("50K category")
    func fiftyKCategory() {
        #expect(RaceCategory.from(effectiveDistanceKm: 42) == .fiftyK)
        #expect(RaceCategory.from(effectiveDistanceKm: 55) == .fiftyK)
        #expect(RaceCategory.from(effectiveDistanceKm: 79) == .fiftyK)
    }

    @Test("100K category")
    func hundredKCategory() {
        #expect(RaceCategory.from(effectiveDistanceKm: 80) == .hundredK)
        #expect(RaceCategory.from(effectiveDistanceKm: 110) == .hundredK)
        #expect(RaceCategory.from(effectiveDistanceKm: 160) == .hundredK)
    }

    @Test("100 Miles category")
    func hundredMilesCategory() {
        // The boundary sits at 161 km — the actual distance of a 100-mile
        // race (160.9 km) — not an arbitrary lower "effective km" figure.
        #expect(RaceCategory.from(effectiveDistanceKm: 161) == .hundredMiles)
        #expect(RaceCategory.from(effectiveDistanceKm: 200) == .hundredMiles)
        #expect(RaceCategory.from(effectiveDistanceKm: 219) == .hundredMiles)
    }

    @Test("A hilly 100K stays 100K instead of being pushed into 100 Miles by its elevation")
    func hillyHundredKStaysHundredK() {
        // Reported bug: 100 km + 5000 m D+ → effective = 100 + 50 = 150 km,
        // which used to cross the old 140 km boundary into `.hundredMiles`
        // — demanding that category's higher minimum prep weeks for what
        // is still, in real terms, a 100K race with a lot of climbing.
        let effectiveKm = 100.0 + 5000.0 / 100.0
        #expect(effectiveKm == 150)
        #expect(RaceCategory.from(effectiveDistanceKm: effectiveKm) == .hundredK)
    }

    @Test("Ultra Long category")
    func ultraLongCategory() {
        #expect(RaceCategory.from(effectiveDistanceKm: 220) == .ultraLong)
        #expect(RaceCategory.from(effectiveDistanceKm: 300) == .ultraLong)
    }

    @Test("UTMB classifies as Ultra Long", .tags(.domain))
    func utmbIsUltraLong() {
        // UTMB: 171km + 10000m D+ → effective = 171 + 100 = 271km
        let effectiveKm = 171.0 + 10000.0 / 100.0
        #expect(RaceCategory.from(effectiveDistanceKm: effectiveKm) == .ultraLong)
    }

    @Test("50K trail race with moderate elevation")
    func fiftyKWithElevation() {
        // 50km + 2000m D+ → effective = 50 + 20 = 70km → fiftyK
        let effectiveKm = 50.0 + 2000.0 / 100.0
        #expect(RaceCategory.from(effectiveDistanceKm: effectiveKm) == .fiftyK)
    }
}

extension Tag {
    @Tag static var domain: Self
}
