import Foundation

enum ReadinessStatus: String, Codable, Sendable {
    case primed
    case ready
    case moderate
    case fatigued
    case needsRest
}
