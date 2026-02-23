import Foundation
import Testing
@testable import UltraTrain

@Suite("TrainingPlanRemoteMapper Tests")
struct TrainingPlanRemoteMapperTests {

    // MARK: - toDomain

    @Test("toDomain decodes valid planJson to TrainingPlan")
    func toDomainDecodesValidJson() {
        let plan = makePlan()
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try! encoder.encode(plan)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        let dto = TrainingPlanResponseDTO(
            id: plan.id.uuidString,
            targetRaceName: "UTMB",
            targetRaceDate: "2026-08-28T06:00:00Z",
            totalWeeks: plan.weeks.count,
            planJson: jsonString,
            createdAt: nil,
            updatedAt: nil
        )

        let result = TrainingPlanRemoteMapper.toDomain(from: dto)

        #expect(result != nil)
        #expect(result?.id == plan.id)
        #expect(result?.weeks.count == 1)
        #expect(result?.weeks.first?.sessions.count == 1)
    }

    @Test("toDomain returns nil for invalid JSON")
    func toDomainReturnsNilForInvalidJson() {
        let dto = TrainingPlanResponseDTO(
            id: "some-id",
            targetRaceName: "Race",
            targetRaceDate: "2026-08-28T06:00:00Z",
            totalWeeks: 1,
            planJson: "{ invalid json }}}",
            createdAt: nil,
            updatedAt: nil
        )

        let result = TrainingPlanRemoteMapper.toDomain(from: dto)
        #expect(result == nil)
    }

    @Test("toDomain returns nil for empty planJson")
    func toDomainReturnsNilForEmptyJson() {
        let dto = TrainingPlanResponseDTO(
            id: "some-id",
            targetRaceName: "Race",
            targetRaceDate: "2026-08-28T06:00:00Z",
            totalWeeks: 0,
            planJson: "",
            createdAt: nil,
            updatedAt: nil
        )

        let result = TrainingPlanRemoteMapper.toDomain(from: dto)
        #expect(result == nil)
    }

    // MARK: - toUploadDTO

    @Test("toUploadDTO encodes plan to JSON string")
    func toUploadDTOEncodesPlan() {
        let plan = makePlan()
        let raceDate = Date()

        let dto = TrainingPlanRemoteMapper.toUploadDTO(
            plan: plan,
            raceName: "UTMB",
            raceDate: raceDate
        )

        #expect(dto != nil)
        #expect(dto?.planId == plan.id.uuidString)
        #expect(dto?.targetRaceName == "UTMB")
        #expect(dto?.totalWeeks == 1)
        #expect(dto?.idempotencyKey == plan.id.uuidString)
        #expect(dto?.planJson.contains("weeks") == true)
    }

    // MARK: - Round-trip

    @Test("Upload then restore preserves plan structure")
    func roundTripPreservesPlan() {
        let original = makePlan()

        let uploadDTO = TrainingPlanRemoteMapper.toUploadDTO(
            plan: original,
            raceName: "Trail Race",
            raceDate: Date()
        )!

        let responseDTO = TrainingPlanResponseDTO(
            id: uploadDTO.planId,
            targetRaceName: uploadDTO.targetRaceName,
            targetRaceDate: uploadDTO.targetRaceDate,
            totalWeeks: uploadDTO.totalWeeks,
            planJson: uploadDTO.planJson,
            createdAt: nil,
            updatedAt: nil
        )

        let restored = TrainingPlanRemoteMapper.toDomain(from: responseDTO)

        #expect(restored != nil)
        #expect(restored?.id == original.id)
        #expect(restored?.weeks.count == original.weeks.count)
        #expect(restored?.athleteId == original.athleteId)
        #expect(restored?.targetRaceId == original.targetRaceId)
    }

    // MARK: - Helpers

    private func makePlan() -> TrainingPlan {
        let session = TrainingSession(
            id: UUID(),
            date: Date(),
            type: .longRun,
            plannedDistanceKm: 25,
            plannedElevationGainM: 800,
            plannedDuration: 10800,
            intensity: .moderate,
            description: "Long trail run",
            isCompleted: false,
            isSkipped: false
        )

        let week = TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: Date(),
            endDate: Date().adding(days: 6),
            phase: .base,
            sessions: [session],
            isRecoveryWeek: false,
            targetVolumeKm: 50,
            targetElevationGainM: 2000
        )

        return TrainingPlan(
            id: UUID(),
            athleteId: UUID(),
            targetRaceId: UUID(),
            createdAt: Date(),
            weeks: [week],
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )
    }
}
