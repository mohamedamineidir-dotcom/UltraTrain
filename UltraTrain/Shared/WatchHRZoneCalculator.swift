import Foundation

enum WatchHRZoneCalculator {

    /// Returns HR zone 1-5 using Karvonen formula
    static func zone(heartRate: Int, maxHR: Int, restingHR: Int) -> Int {
        guard maxHR > restingHR, heartRate > 0 else { return 1 }
        let hrReserve = Double(maxHR - restingHR)
        let intensity = Double(heartRate - restingHR) / hrReserve

        switch intensity {
        case ..<0.6:
            return 1   // Recovery
        case 0.6..<0.7:
            return 2   // Aerobic
        case 0.7..<0.8:
            return 3   // Tempo
        case 0.8..<0.9:
            return 4   // Threshold
        default:
            return 5   // VO2max
        }
    }

    static func zoneName(_ zone: Int) -> String {
        switch zone {
        case 1: return "Recovery"
        case 2: return "Aerobic"
        case 3: return "Tempo"
        case 4: return "Threshold"
        case 5: return "VO2max"
        default: return "Unknown"
        }
    }

    static func zoneColorName(_ zone: Int) -> String {
        switch zone {
        case 1: return "green"
        case 2: return "blue"
        case 3: return "yellow"
        case 4: return "orange"
        case 5: return "red"
        default: return "gray"
        }
    }
}
