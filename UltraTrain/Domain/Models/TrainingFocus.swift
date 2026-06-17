import Foundation

/// What an athlete who is NOT preparing for a race wants out of their
/// training. Drives the general-fitness plan's easy:quality mix, session
/// types, and how aggressively volume trends. Unlike a race plan, none of
/// these periodise toward a peak/taper — they are sustainable, repeating
/// structures.
enum TrainingFocus: String, CaseIterable, Codable, Sendable {
    /// Aerobic development. Most volume progression, mostly easy mileage,
    /// one threshold/tempo touch, strides for economy.
    case buildBase
    /// Balanced upkeep. Hold current fitness with a steady tempo + a
    /// rotating second quality session for stronger athletes.
    case maintainFitness
    /// Speed retention. Two quality sessions (intervals/fartlek + tempo)
    /// and strides, flatter volume — keeps the top end sharp.
    case keepSpeedSharp
    /// Consistency and general health/weight. Frequent easy aerobic running,
    /// one gentle quality session, gentle volume — sustainable calorie burn.
    case generalHealth

    var displayName: String {
        switch self {
        case .buildBase:       String(localized: "focus.buildBase", defaultValue: "Build aerobic base")
        case .maintainFitness: String(localized: "focus.maintain", defaultValue: "Maintain fitness")
        case .keepSpeedSharp:  String(localized: "focus.speed", defaultValue: "Keep speed sharp")
        case .generalHealth:   String(localized: "focus.health", defaultValue: "General health & weight")
        }
    }

    var subtitle: String {
        switch self {
        case .buildBase:       String(localized: "focus.buildBase.sub", defaultValue: "Grow your aerobic engine with easy mileage and a weekly tempo.")
        case .maintainFitness: String(localized: "focus.maintain.sub", defaultValue: "Hold your current fitness with a balanced, sustainable week.")
        case .keepSpeedSharp:  String(localized: "focus.speed.sub", defaultValue: "Two quality sessions a week to keep your speed and edge.")
        case .generalHealth:   String(localized: "focus.health.sub", defaultValue: "Frequent easy running for fitness, energy and weight management.")
        }
    }

    /// SF Symbol for the onboarding option card.
    var iconName: String {
        switch self {
        case .buildBase:       "lungs.fill"
        case .maintainFitness: "gauge.with.dots.needle.50percent"
        case .keepSpeedSharp:  "bolt.fill"
        case .generalHealth:   "heart.fill"
        }
    }

    /// Quality (hard) sessions per week before the experience/frequency cap.
    var baseQualityCount: Int {
        switch self {
        case .buildBase:       1
        case .maintainFitness: 1
        case .keepSpeedSharp:  2
        case .generalHealth:   1
        }
    }

    /// Per-mesocycle volume growth factor (compounded each 4-week block).
    /// All are gentle, none ramp toward race volume.
    var blockGrowth: Double {
        switch self {
        case .buildBase:       1.05   // ~5% / month
        case .keepSpeedSharp:  1.02
        case .maintainFitness: 1.00   // flat
        case .generalHealth:   1.00
        }
    }
}
