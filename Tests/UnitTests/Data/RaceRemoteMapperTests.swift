import Foundation
import Testing
@testable import UltraTrain

@Suite("RaceRemoteMapper Tests")
struct RaceRemoteMapperTests {

    // MARK: - toUploadDTO

    @Test("toUploadDTO maps Race to upload DTO")
    func toUploadDTOMapsRace() {
        let race = makeRace()
        let dto = RaceRemoteMapper.toUploadDTO(race)

        #expect(dto != nil)
        #expect(dto?.raceId == race.id.uuidString)
        #expect(dto?.name == "UTMB")
        #expect(dto?.distanceKm == 171.0)
        #expect(dto?.elevationGainM == 10000.0)
        #expect(dto?.priority == "aRace")
        #expect(dto?.idempotencyKey == race.id.uuidString)
        #expect(dto?.raceJson.isEmpty == false)
    }

    @Test("toUploadDTO raceJson contains encoded race data")
    func toUploadDTOContainsRaceData() {
        let race = makeRace()
        let dto = RaceRemoteMapper.toUploadDTO(race)!

        #expect(dto.raceJson.contains("UTMB"))
        #expect(dto.raceJson.contains("171"))
        #expect(dto.raceJson.contains("10000"))
    }

    // MARK: - toDomain

    @Test("toDomain decodes valid raceJson to Race")
    func toDomainDecodesValidJson() {
        let original = makeRace()
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try! encoder.encode(original)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        let dto = RaceResponseDTO(
            id: UUID().uuidString,
            raceId: original.id.uuidString,
            name: original.name,
            date: "2026-08-28T06:00:00Z",
            distanceKm: original.distanceKm,
            elevationGainM: original.elevationGainM,
            priority: "aRace",
            raceJson: jsonString,
            createdAt: nil,
            updatedAt: nil
        )

        let result = RaceRemoteMapper.toDomain(from: dto)

        #expect(result != nil)
        #expect(result?.id == original.id)
        #expect(result?.name == "UTMB")
        #expect(result?.distanceKm == 171.0)
        #expect(result?.elevationGainM == 10000.0)
        #expect(result?.priority == .aRace)
        #expect(result?.terrainDifficulty == .technical)
        #expect(result?.checkpoints.count == 1)
    }

    @Test("toDomain returns nil for invalid JSON")
    func toDomainReturnsNilForInvalidJson() {
        let dto = RaceResponseDTO(
            id: UUID().uuidString,
            raceId: UUID().uuidString,
            name: "Race",
            date: "2026-08-28T06:00:00Z",
            distanceKm: 100,
            elevationGainM: 5000,
            priority: "aRace",
            raceJson: "{ not valid json }}}",
            createdAt: nil,
            updatedAt: nil
        )

        let result = RaceRemoteMapper.toDomain(from: dto)
        #expect(result == nil)
    }

    @Test("toDomain returns nil for empty raceJson")
    func toDomainReturnsNilForEmptyJson() {
        let dto = RaceResponseDTO(
            id: UUID().uuidString,
            raceId: UUID().uuidString,
            name: "Race",
            date: "2026-08-28T06:00:00Z",
            distanceKm: 100,
            elevationGainM: 5000,
            priority: "aRace",
            raceJson: "",
            createdAt: nil,
            updatedAt: nil
        )

        let result = RaceRemoteMapper.toDomain(from: dto)
        #expect(result == nil)
    }

    // MARK: - Round-trip

    @Test("Upload then restore preserves race data")
    func roundTripPreservesRace() {
        let original = makeRace()

        let uploadDTO = RaceRemoteMapper.toUploadDTO(original)!

        let responseDTO = RaceResponseDTO(
            id: UUID().uuidString,
            raceId: uploadDTO.raceId,
            name: uploadDTO.name,
            date: uploadDTO.date,
            distanceKm: uploadDTO.distanceKm,
            elevationGainM: uploadDTO.elevationGainM,
            priority: uploadDTO.priority,
            raceJson: uploadDTO.raceJson,
            createdAt: nil,
            updatedAt: nil
        )

        let restored = RaceRemoteMapper.toDomain(from: responseDTO)

        #expect(restored != nil)
        #expect(restored?.id == original.id)
        #expect(restored?.name == original.name)
        #expect(restored?.distanceKm == original.distanceKm)
        #expect(restored?.elevationGainM == original.elevationGainM)
        #expect(restored?.elevationLossM == original.elevationLossM)
        #expect(restored?.priority == original.priority)
        #expect(restored?.terrainDifficulty == original.terrainDifficulty)
        #expect(restored?.checkpoints.count == original.checkpoints.count)
        #expect(restored?.checkpoints.first?.name == "Les Contamines")
    }

    @Test("Round-trip preserves race with all goal types")
    func roundTripPreservesGoalTypes() {
        let goals: [RaceGoal] = [
            .finish,
            .targetTime(86400),
            .targetRanking(50)
        ]

        for goal in goals {
            var race = makeRace()
            race.goalType = goal

            let uploadDTO = RaceRemoteMapper.toUploadDTO(race)!
            let responseDTO = RaceResponseDTO(
                id: UUID().uuidString,
                raceId: uploadDTO.raceId,
                name: uploadDTO.name,
                date: uploadDTO.date,
                distanceKm: uploadDTO.distanceKm,
                elevationGainM: uploadDTO.elevationGainM,
                priority: uploadDTO.priority,
                raceJson: uploadDTO.raceJson,
                createdAt: nil,
                updatedAt: nil
            )

            let restored = RaceRemoteMapper.toDomain(from: responseDTO)
            #expect(restored?.goalType == goal)
        }
    }

    // MARK: - Helpers

    private func makeRace() -> Race {
        Race(
            id: UUID(),
            name: "UTMB",
            date: Date(),
            distanceKm: 171.0,
            elevationGainM: 10000.0,
            elevationLossM: 10000.0,
            priority: .aRace,
            goalType: .targetTime(86400),
            checkpoints: [
                Checkpoint(
                    id: UUID(),
                    name: "Les Contamines",
                    distanceFromStartKm: 31.0,
                    elevationM: 1164.0,
                    hasAidStation: true
                )
            ],
            terrainDifficulty: .technical
        )
    }
}
