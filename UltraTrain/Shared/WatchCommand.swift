import Foundation

enum WatchCommand: String, Codable, Sendable {
    case pause
    case resume
    case stop
    case dismissReminder
}
