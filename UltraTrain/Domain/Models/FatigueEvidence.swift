import Foundation

struct FatigueEvidence: Equatable, Sendable {
    var metric: String
    var baselineValue: Double
    var currentValue: Double
    var changePercent: Double
    var period: String
}
