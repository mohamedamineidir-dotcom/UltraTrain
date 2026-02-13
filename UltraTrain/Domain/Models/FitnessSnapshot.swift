import Foundation

struct FitnessSnapshot: Identifiable, Equatable, Sendable {
    let id: UUID
    var date: Date
    var fitness: Double    // CTL — chronic training load (42-day EMA)
    var fatigue: Double    // ATL — acute training load (7-day EMA)
    var form: Double       // TSB — training stress balance (fitness - fatigue)
    var weeklyVolumeKm: Double
    var weeklyElevationGainM: Double
    var weeklyDuration: TimeInterval
    var acuteToChronicRatio: Double
}
