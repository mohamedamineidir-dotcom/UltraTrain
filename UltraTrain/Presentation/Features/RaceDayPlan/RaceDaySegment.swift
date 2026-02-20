import Foundation

struct RaceDaySegment: Identifiable, Sendable {
    let id: UUID
    let checkpointName: String
    let distanceFromStartKm: Double
    let segmentDistanceKm: Double
    let segmentElevationGainM: Double
    let hasAidStation: Bool
    let expectedArrivalTime: Date
    let expectedCumulativeTime: TimeInterval
    let expectedSegmentDuration: TimeInterval
    let nutritionEntries: [NutritionEntry]
    let cumulativeCalories: Int
    let cumulativeHydrationMl: Int
    let cumulativeSodiumMg: Int
    let targetPaceSecondsPerKm: Double
    let conservativePaceSecondsPerKm: Double
    let aggressivePaceSecondsPerKm: Double
    let pacingZone: RacePacingCalculator.PacingZone
    let aidStationDwellTime: TimeInterval
}
