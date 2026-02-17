import Foundation

struct GPXParseResult: Sendable {
    var name: String?
    var date: Date?
    var trackPoints: [TrackPoint]
}
