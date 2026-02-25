import Foundation

enum IntervalTrigger: Equatable, Sendable, Codable {
    case duration(seconds: TimeInterval)
    case distance(km: Double)

    var displayText: String {
        switch self {
        case .duration(let seconds):
            let min = Int(seconds) / 60
            let sec = Int(seconds) % 60
            return sec > 0 ? "\(min)m \(sec)s" : "\(min)m"
        case .distance(let km):
            return String(format: "%.2f km", km)
        }
    }

    var isDuration: Bool {
        if case .duration = self { return true }
        return false
    }

    var isDistance: Bool {
        if case .distance = self { return true }
        return false
    }
}
