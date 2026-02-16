import Testing
import Foundation
@testable import UltraTrain

@Suite("RaceSwiftDataMapper Tests")
struct RaceSwiftDataMapperTests {

    // MARK: - Helpers

    private func makeRace(
        checkpoints: [Checkpoint] = [],
        goalType: RaceGoal = .finish,
        priority: RacePriority = .aRace,
        terrain: TerrainDifficulty = .moderate
    ) -> Race {
        Race(
            id: UUID(),
            name: "UTMB",
            date: Date(timeIntervalSince1970: 1_700_000_000),
            distanceKm: 171,
            elevationGainM: 10000,
            elevationLossM: 10000,
            priority: priority,
            goalType: goalType,
            checkpoints: checkpoints,
            terrainDifficulty: terrain
        )
    }

    private func makeCheckpoint(
        name: String = "Aid Station",
        distanceKm: Double = 20,
        elevationM: Double = 1500,
        hasAidStation: Bool = true
    ) -> Checkpoint {
        Checkpoint(
            id: UUID(),
            name: name,
            distanceFromStartKm: distanceKm,
            elevationM: elevationM,
            hasAidStation: hasAidStation
        )
    }

    // MARK: - Round-Trip Tests

    @Test("Round-trip preserves race fields")
    func roundTripPreservesFields() {
        let race = makeRace()
        let model = RaceSwiftDataMapper.toSwiftData(race)
        let restored = RaceSwiftDataMapper.toDomain(model)

        #expect(restored != nil)
        #expect(restored?.id == race.id)
        #expect(restored?.name == race.name)
        #expect(restored?.date == race.date)
        #expect(restored?.distanceKm == race.distanceKm)
        #expect(restored?.elevationGainM == race.elevationGainM)
        #expect(restored?.elevationLossM == race.elevationLossM)
        #expect(restored?.priority == race.priority)
        #expect(restored?.terrainDifficulty == race.terrainDifficulty)
    }

    @Test("Round-trip preserves checkpoints")
    func roundTripPreservesCheckpoints() {
        let checkpoints = [
            makeCheckpoint(name: "Les Contamines", distanceKm: 31, elevationM: 1200),
            makeCheckpoint(name: "Les Chapieux", distanceKm: 50, elevationM: 1549),
            makeCheckpoint(name: "Courmayeur", distanceKm: 78, elevationM: 1189, hasAidStation: true)
        ]
        let race = makeRace(checkpoints: checkpoints)
        let model = RaceSwiftDataMapper.toSwiftData(race)
        let restored = RaceSwiftDataMapper.toDomain(model)

        #expect(restored != nil)
        #expect(restored?.checkpoints.count == 3)
        #expect(restored?.checkpoints[0].name == "Les Contamines")
        #expect(restored?.checkpoints[1].name == "Les Chapieux")
        #expect(restored?.checkpoints[2].name == "Courmayeur")
    }

    @Test("Checkpoints are sorted by distance in toDomain")
    func checkpointsSortedByDistance() {
        let checkpoints = [
            makeCheckpoint(name: "Far", distanceKm: 100, elevationM: 2000),
            makeCheckpoint(name: "Near", distanceKm: 10, elevationM: 500),
            makeCheckpoint(name: "Mid", distanceKm: 50, elevationM: 1200)
        ]
        let race = makeRace(checkpoints: checkpoints)
        let model = RaceSwiftDataMapper.toSwiftData(race)
        let restored = RaceSwiftDataMapper.toDomain(model)

        #expect(restored?.checkpoints[0].name == "Near")
        #expect(restored?.checkpoints[1].name == "Mid")
        #expect(restored?.checkpoints[2].name == "Far")
    }

    @Test("Checkpoint fields preserved through mapping")
    func checkpointFieldsPreserved() {
        let cp = makeCheckpoint(name: "Col du Bonhomme", distanceKm: 45, elevationM: 2329, hasAidStation: false)
        let race = makeRace(checkpoints: [cp])
        let model = RaceSwiftDataMapper.toSwiftData(race)
        let restored = RaceSwiftDataMapper.toDomain(model)

        let restoredCp = restored?.checkpoints.first
        #expect(restoredCp != nil)
        #expect(restoredCp?.name == "Col du Bonhomme")
        #expect(restoredCp?.distanceFromStartKm == 45)
        #expect(restoredCp?.elevationM == 2329)
        #expect(restoredCp?.hasAidStation == false)
    }

    @Test("Empty checkpoints round-trip correctly")
    func emptyCheckpointsRoundTrip() {
        let race = makeRace(checkpoints: [])
        let model = RaceSwiftDataMapper.toSwiftData(race)
        let restored = RaceSwiftDataMapper.toDomain(model)

        #expect(restored?.checkpoints.isEmpty == true)
    }

    // MARK: - Goal Type Tests

    @Test("Finish goal round-trips")
    func finishGoalRoundTrip() {
        let race = makeRace(goalType: .finish)
        let model = RaceSwiftDataMapper.toSwiftData(race)
        let restored = RaceSwiftDataMapper.toDomain(model)

        #expect(restored?.goalType == .finish)
    }

    @Test("Target time goal round-trips")
    func targetTimeGoalRoundTrip() {
        let race = makeRace(goalType: .targetTime(46 * 3600))
        let model = RaceSwiftDataMapper.toSwiftData(race)
        let restored = RaceSwiftDataMapper.toDomain(model)

        #expect(restored?.goalType == .targetTime(46 * 3600))
    }

    @Test("Target ranking goal round-trips")
    func targetRankingGoalRoundTrip() {
        let race = makeRace(goalType: .targetRanking(100))
        let model = RaceSwiftDataMapper.toSwiftData(race)
        let restored = RaceSwiftDataMapper.toDomain(model)

        #expect(restored?.goalType == .targetRanking(100))
    }

    // MARK: - Invalid Data

    @Test("Invalid priority raw value returns nil")
    func invalidPriorityReturnsNil() {
        let model = RaceSwiftDataModel(
            id: UUID(),
            name: "Test",
            date: .now,
            distanceKm: 50,
            elevationGainM: 1000,
            elevationLossM: 1000,
            priorityRaw: "invalid",
            goalTypeRaw: "finish",
            goalValue: nil,
            terrainDifficultyRaw: "moderate"
        )
        let result = RaceSwiftDataMapper.toDomain(model)
        #expect(result == nil)
    }

    @Test("Invalid terrain raw value returns nil")
    func invalidTerrainReturnsNil() {
        let model = RaceSwiftDataModel(
            id: UUID(),
            name: "Test",
            date: .now,
            distanceKm: 50,
            elevationGainM: 1000,
            elevationLossM: 1000,
            priorityRaw: "aRace",
            goalTypeRaw: "finish",
            goalValue: nil,
            terrainDifficultyRaw: "invalid"
        )
        let result = RaceSwiftDataMapper.toDomain(model)
        #expect(result == nil)
    }
}
