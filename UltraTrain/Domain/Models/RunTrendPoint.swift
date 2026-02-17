import Foundation

struct RunTrendPoint: Identifiable, Equatable, Sendable {
    let id: UUID
    let date: Date
    let distanceKm: Double
    let elevationGainM: Double
    let duration: TimeInterval
    let averagePaceSecondsPerKm: Double
    let averageHeartRate: Int?
    let rollingAveragePace: Double?
    let rollingAverageHR: Double?
}
