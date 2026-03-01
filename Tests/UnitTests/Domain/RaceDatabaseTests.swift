import Testing
@testable import UltraTrain

@Suite("RaceDatabase Tests")
struct RaceDatabaseTests {

    @Test("Database contains at least 130 races")
    func databaseHasMinimumRaces() {
        #expect(RaceDatabase.races.count >= 130)
    }

    @Test("Search finds UTMB by short name")
    func searchByShortName() {
        let results = RaceDatabase.search(query: "UTMB")
        #expect(!results.isEmpty)
        #expect(results.contains { $0.shortName == "UTMB" })
    }

    @Test("Search finds races by country")
    func searchByCountry() {
        let results = RaceDatabase.search(query: "USA")
        #expect(results.count >= 3)
    }

    @Test("Search is case-insensitive")
    func caseInsensitiveSearch() {
        let upper = RaceDatabase.search(query: "UTMB")
        let lower = RaceDatabase.search(query: "utmb")
        #expect(upper.count == lower.count)
    }

    @Test("Empty query returns no results")
    func emptyQueryReturnsEmpty() {
        let results = RaceDatabase.search(query: "")
        #expect(results.isEmpty)
    }

    @Test("Search finds Diagonale des Fous")
    func searchDiagonale() {
        let results = RaceDatabase.search(query: "Diagonale")
        #expect(!results.isEmpty)
        #expect(results.first?.distanceKm == 165)
    }

    @Test("All races have positive distance and elevation")
    func allRacesHaveValidData() {
        for race in RaceDatabase.races {
            #expect(race.distanceKm > 0, "Race \(race.name) has invalid distance")
            #expect(race.elevationGainM >= 0, "Race \(race.name) has invalid D+")
            #expect(race.elevationLossM >= 0, "Race \(race.name) has invalid D-")
            #expect(!race.name.isEmpty, "Race has empty name")
            #expect(!race.country.isEmpty, "Race \(race.name) has empty country")
        }
    }
}
