import Foundation

struct MLFinishTimePrediction: Identifiable, Equatable, Sendable {
    let id: UUID
    var predictedTimeSeconds: TimeInterval
    var confidencePercent: Int
    var algorithmicTimeSeconds: TimeInterval
    var mlTimeSeconds: TimeInterval
    var blendWeight: Double  // 0.0 = pure algorithmic, 1.0 = pure ML
    var modelVersion: String
    var predictionDate: Date
    var runCount: Int  // how many runs the model was informed by

    var predictedTimeFormatted: String {
        let hours = Int(predictedTimeSeconds) / 3600
        let minutes = (Int(predictedTimeSeconds) % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %02dmin", hours, minutes)
        }
        return String(format: "%dmin", minutes)
    }

    var confidenceLabel: String {
        switch confidencePercent {
        case 75...: return "High"
        case 50..<75: return "Medium"
        default: return "Low"
        }
    }
}
