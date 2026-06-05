import Foundation
import Testing
@testable import UltraTrain

@Suite("Race-week templates")
struct RaceWeekTemplatesTests {

    // MARK: - Helpers

    private func makeRoadRace(
        distanceKm: Double,
        daysFromMonday: Int = 5  // Saturday by default
    ) -> Race {
        let monday = makeMondayBaseline()
        let raceDate = monday.addingTimeInterval(TimeInterval(daysFromMonday * 86400))
        return Race(
            id: UUID(), name: "Test", date: raceDate,
            distanceKm: distanceKm, elevationGainM: 0, elevationLossM: 0,
            priority: .aRace, goalType: .finish, checkpoints: [],
            terrainDifficulty: .easy, raceType: .road
        )
    }

    private func makeTrailRace(
        distanceKm: Double,
        elevationGainM: Double,
        daysFromMonday: Int = 5
    ) -> Race {
        let monday = makeMondayBaseline()
        let raceDate = monday.addingTimeInterval(TimeInterval(daysFromMonday * 86400))
        return Race(
            id: UUID(), name: "Test Trail", date: raceDate,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM, elevationLossM: elevationGainM,
            priority: .aRace, goalType: .finish, checkpoints: [],
            terrainDifficulty: .technical, raceType: .trail
        )
    }

    private func makeMondayBaseline() -> Date {
        // Pick a known Monday: 2026-08-24 is a Monday.
        var c = DateComponents(); c.year = 2026; c.month = 8; c.day = 24
        return Calendar.current.date(from: c)!
    }

    // MARK: - Road

    @Test("Road: marathon week includes a .race session at race day")
    func roadMarathonIncludesRaceSession() {
        let race = makeRoadRace(distanceKm: 42.195, daysFromMonday: 5) // Saturday
        let templates = RoadRaceWeekTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .balanced, weekStartDate: makeMondayBaseline()
        )
        let raceDay = templates.first { $0.type == .race }
        #expect(raceDay != nil)
        #expect(raceDay?.dayOffset == 5)
        #expect(raceDay?.intensity == .maxEffort)
        #expect(raceDay?.durationSeconds ?? 0 > 0)
    }

    @Test("Road: 5K week prep ends with a tune-up at Day -5")
    func roadFiveKHasDayMinus5Tuneup() {
        let race = makeRoadRace(distanceKm: 5)
        let templates = RoadRaceWeekTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .balanced, weekStartDate: makeMondayBaseline()
        )
        // Race Saturday (day 5). Day -5 = day 0 (Monday).
        let dayMinus5 = templates.first { $0.dayOffset == 0 }
        #expect(dayMinus5?.type == .intervals)
    }

    @Test("Road: beginner drops the quality session")
    func roadBeginnerNoQuality() {
        let race = makeRoadRace(distanceKm: 21.1)
        let templates = RoadRaceWeekTemplates.sessions(
            targetRace: race, experience: .beginner,
            philosophy: .balanced, weekStartDate: makeMondayBaseline()
        )
        let qualityCount = templates.filter {
            $0.type == .intervals || $0.type == .tempo
        }.count
        #expect(qualityCount == 0)
    }

    @Test("Road: enjoyment philosophy drops quality")
    func roadEnjoymentNoQuality() {
        let race = makeRoadRace(distanceKm: 10)
        let templates = RoadRaceWeekTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .enjoyment, weekStartDate: makeMondayBaseline()
        )
        let qualityCount = templates.filter {
            $0.type == .intervals || $0.type == .tempo
        }.count
        #expect(qualityCount == 0)
    }

    @Test("Road: post-race day in same week becomes rest")
    func roadPostRaceDayIsRest() {
        // Race on Saturday (day 5) → Sunday (day 6) should be rest.
        let race = makeRoadRace(distanceKm: 42.195, daysFromMonday: 5)
        let templates = RoadRaceWeekTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .balanced, weekStartDate: makeMondayBaseline()
        )
        let sunday = templates.first { $0.dayOffset == 6 }
        #expect(sunday?.type == .rest)
    }

    @Test("Road: covers all 7 days exactly once")
    func roadCoversFullWeek() {
        let race = makeRoadRace(distanceKm: 42.195)
        let templates = RoadRaceWeekTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .balanced, weekStartDate: makeMondayBaseline()
        )
        let dayOffsets = Set(templates.map(\.dayOffset))
        #expect(dayOffsets == Set(0...6))
        #expect(templates.count == 7)
    }

    // MARK: - Trail

    @Test("Trail: 100K race-day session has duration matching estimatedDuration")
    func trailRaceDayDurationMatches() {
        let race = makeTrailRace(distanceKm: 101, elevationGainM: 5000)
        let templates = TrailRaceWeekTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .balanced, weekStartDate: makeMondayBaseline()
        )
        let raceDay = templates.first { $0.type == .race }
        #expect(raceDay != nil)
        let expected = race.estimatedDuration(experience: .intermediate)
        #expect(raceDay?.durationSeconds == expected)
    }

    @Test("Trail: mountain race (≥40 m/km D+) strips quality on Day -5")
    func trailMountainStripsDayMinus5Quality() {
        // 50K with 3500m D+ → density 70 m/km → mountain
        let race = makeTrailRace(distanceKm: 50, elevationGainM: 3500)
        let templates = TrailRaceWeekTemplates.sessions(
            targetRace: race, experience: .advanced,
            philosophy: .performance, weekStartDate: makeMondayBaseline()
        )
        // Race Saturday (day 5) → Day -5 = day 0. Quality is stripped: the
        // mountain day-5 is an easy primer, which the race-week active-day
        // cap may further demote to a full rest day. Either way it is no
        // longer a quality session.
        let dayMinus5 = templates.first { $0.dayOffset == 0 }
        #expect(dayMinus5?.type == .recovery || dayMinus5?.type == .rest)
    }

    @Test("Trail: flat 50K + advanced + performance allows Day -5 light quality")
    func trailFlatFiftyKAllowsLightQuality() {
        // 50K with 1500m D+ → density 30 m/km → not mountain
        let race = makeTrailRace(distanceKm: 50, elevationGainM: 1500)
        let templates = TrailRaceWeekTemplates.sessions(
            targetRace: race, experience: .advanced,
            philosophy: .performance, weekStartDate: makeMondayBaseline()
        )
        // Day -5 should be tempo (light primer for elite/advanced)
        let dayMinus5 = templates.first { $0.dayOffset == 0 }
        #expect(dayMinus5?.type == .tempo)
    }

    @Test("Trail: 100-mile week is all recovery + rest, no quality")
    func trailHundredMileNoQuality() {
        let race = makeTrailRace(distanceKm: 161, elevationGainM: 5500)
        let templates = TrailRaceWeekTemplates.sessions(
            targetRace: race, experience: .advanced,
            philosophy: .balanced, weekStartDate: makeMondayBaseline()
        )
        let qualityTypes: Set<SessionType> = [.intervals, .tempo, .verticalGain]
        let qualityCount = templates.filter { qualityTypes.contains($0.type) }.count
        #expect(qualityCount == 0)
    }

    @Test("Trail: beginner gets more rest")
    func trailBeginnerMoreRest() {
        let race = makeTrailRace(distanceKm: 50, elevationGainM: 1500)
        let beginner = TrailRaceWeekTemplates.sessions(
            targetRace: race, experience: .beginner,
            philosophy: .balanced, weekStartDate: makeMondayBaseline()
        )
        let advanced = TrailRaceWeekTemplates.sessions(
            targetRace: race, experience: .advanced,
            philosophy: .performance, weekStartDate: makeMondayBaseline()
        )
        let beginnerRest = beginner.filter { $0.type == .rest }.count
        let advancedRest = advanced.filter { $0.type == .rest }.count
        #expect(beginnerRest >= advancedRest)
    }

    @Test("Trail: short trail (35K) week has more activity than 100-miler")
    func trailShortVsHundredVolumeShape() {
        let shortTrail = makeTrailRace(distanceKm: 30, elevationGainM: 1000)
        let hundredMile = makeTrailRace(distanceKm: 161, elevationGainM: 5500)
        let shortTpl = TrailRaceWeekTemplates.sessions(
            targetRace: shortTrail, experience: .intermediate,
            philosophy: .balanced, weekStartDate: makeMondayBaseline()
        )
        let longTpl = TrailRaceWeekTemplates.sessions(
            targetRace: hundredMile, experience: .intermediate,
            philosophy: .balanced, weekStartDate: makeMondayBaseline()
        )
        // Compare prep volume (excluding race day itself).
        let shortPrep = shortTpl.filter { $0.type != .race && $0.type != .rest }
            .reduce(0.0) { $0 + $1.durationSeconds }
        let longPrep = longTpl.filter { $0.type != .race && $0.type != .rest }
            .reduce(0.0) { $0 + $1.durationSeconds }
        #expect(shortPrep > longPrep)
    }

    @Test("Trail: covers all 7 days exactly once")
    func trailCoversFullWeek() {
        let race = makeTrailRace(distanceKm: 50, elevationGainM: 1500)
        let templates = TrailRaceWeekTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .balanced, weekStartDate: makeMondayBaseline()
        )
        let dayOffsets = Set(templates.map(\.dayOffset))
        #expect(dayOffsets == Set(0...6))
        #expect(templates.count == 7)
    }

    @Test("Trail: race-day description includes D+")
    func trailRaceDescriptionIncludesElevation() {
        let race = makeTrailRace(distanceKm: 101, elevationGainM: 6500)
        let templates = TrailRaceWeekTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .balanced, weekStartDate: makeMondayBaseline()
        )
        let raceDay = templates.first { $0.type == .race }
        #expect(raceDay?.description.contains("6500") == true)
    }

    // MARK: - Race-day placement

    @Test("Race day lands on Sunday (day 6) when race is Sunday")
    func raceOnSunday() {
        let race = makeRoadRace(distanceKm: 42.195, daysFromMonday: 6)
        let templates = RoadRaceWeekTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .balanced, weekStartDate: makeMondayBaseline()
        )
        let raceDay = templates.first { $0.type == .race }
        #expect(raceDay?.dayOffset == 6)
    }

    @Test("Race on early-week (Wednesday) leaves later days as rest")
    func raceOnWednesday() {
        let race = makeRoadRace(distanceKm: 21.1, daysFromMonday: 2)
        let templates = RoadRaceWeekTemplates.sessions(
            targetRace: race, experience: .intermediate,
            philosophy: .balanced, weekStartDate: makeMondayBaseline()
        )
        let raceDay = templates.first { $0.type == .race }
        #expect(raceDay?.dayOffset == 2)
        // Days 3-6 should be rest
        for d in 3...6 {
            let s = templates.first { $0.dayOffset == d }
            #expect(s?.type == .rest, "Day \(d) should be rest after Wednesday race")
        }
    }
}
