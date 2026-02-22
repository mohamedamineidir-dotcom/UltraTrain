import Foundation

enum IntervalPhaseType: String, CaseIterable, Sendable, Codable {
    case warmUp
    case work
    case recovery
    case coolDown

    var displayName: String {
        switch self {
        case .warmUp: return "Warm Up"
        case .work: return "Work"
        case .recovery: return "Recovery"
        case .coolDown: return "Cool Down"
        }
    }

    var iconName: String {
        switch self {
        case .warmUp: return "flame.fill"
        case .work: return "bolt.fill"
        case .recovery: return "heart.fill"
        case .coolDown: return "snowflake"
        }
    }
}

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

struct IntervalPhase: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    var phaseType: IntervalPhaseType
    var trigger: IntervalTrigger
    var targetIntensity: Intensity
    var repeatCount: Int
    var notes: String?

    var totalDuration: TimeInterval {
        switch trigger {
        case .duration(let seconds): return seconds * Double(repeatCount)
        case .distance: return 0
        }
    }
}
