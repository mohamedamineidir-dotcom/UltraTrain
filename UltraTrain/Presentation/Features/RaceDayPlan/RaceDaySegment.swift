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
}
