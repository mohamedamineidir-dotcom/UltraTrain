import Foundation

enum FinishEstimateSwiftDataMapper {

    static func toDomain(_ model: FinishEstimateSwiftDataModel) -> FinishEstimate {
        FinishEstimate(
            id: model.id,
            raceId: model.raceId,
            athleteId: model.athleteId,
            calculatedAt: model.calculatedAt,
            optimisticTime: model.optimisticTime,
            expectedTime: model.expectedTime,
            conservativeTime: model.conservativeTime,
            checkpointSplits: decodeSplits(model.checkpointSplitsData),
            confidencePercent: model.confidencePercent,
            raceResultsUsed: model.raceResultsUsed
        )
    }

    static func toSwiftData(_ estimate: FinishEstimate) -> FinishEstimateSwiftDataModel {
        FinishEstimateSwiftDataModel(
            id: estimate.id,
            raceId: estimate.raceId,
            athleteId: estimate.athleteId,
            calculatedAt: estimate.calculatedAt,
            optimisticTime: estimate.optimisticTime,
            expectedTime: estimate.expectedTime,
            conservativeTime: estimate.conservativeTime,
            checkpointSplitsData: encodeSplits(estimate.checkpointSplits),
            confidencePercent: estimate.confidencePercent,
            raceResultsUsed: estimate.raceResultsUsed
        )
    }

    // MARK: - Checkpoint Splits Encoding

    private struct CodableSplit: Codable {
        let id: UUID
        let checkpointId: UUID
        let checkpointName: String
        let optimisticTime: Double
        let expectedTime: Double
        let conservativeTime: Double
    }

    private static func encodeSplits(_ splits: [CheckpointSplit]) -> Data {
        let codable = splits.map { split in
            CodableSplit(
                id: split.id,
                checkpointId: split.checkpointId,
                checkpointName: split.checkpointName,
                optimisticTime: split.optimisticTime,
                expectedTime: split.expectedTime,
                conservativeTime: split.conservativeTime
            )
        }
        return (try? JSONEncoder().encode(codable)) ?? Data()
    }

    private static func decodeSplits(_ data: Data) -> [CheckpointSplit] {
        guard !data.isEmpty,
              let codable = try? JSONDecoder().decode([CodableSplit].self, from: data) else {
            return []
        }
        return codable.map { split in
            CheckpointSplit(
                id: split.id,
                checkpointId: split.checkpointId,
                checkpointName: split.checkpointName,
                optimisticTime: split.optimisticTime,
                expectedTime: split.expectedTime,
                conservativeTime: split.conservativeTime
            )
        }
    }
}
