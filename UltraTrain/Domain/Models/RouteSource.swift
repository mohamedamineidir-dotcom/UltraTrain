import Foundation

enum RouteSource: String, CaseIterable, Sendable, Codable {
    case gpxImport
    case completedRun
    case manual
}
