import Foundation

enum SessionType: String, CaseIterable, Sendable, Codable {
    case longRun
    case tempo
    case intervals
    case verticalGain
    case backToBack
    case recovery
    case crossTraining
    case rest
}
