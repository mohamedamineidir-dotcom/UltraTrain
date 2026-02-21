import Foundation

enum SessionOptimizer {

    struct Input {
        let plannedSession: TrainingSession?
        let currentPhase: TrainingPhase
        let readiness: ReadinessScore?
        let fatiguePatterns: [FatiguePattern]
        let weather: WeatherSnapshot?
        let availableTimeMinutes: Int?
    }

    static func optimize(input: Input) -> OptimalSession {
        let base = input.plannedSession
        let phase = input.currentPhase
        let readiness = input.readiness
        let fatigue = input.fatiguePatterns
        let weather = input.weather

        var recommendedType = base?.type ?? .recovery
        var intensity = base?.intensity ?? .easy
        var distanceKm = base?.plannedDistanceKm ?? 5.0
        var elevationGainM = base?.plannedElevationGainM ?? 0
        var duration = base?.plannedDuration ?? 2400
        var targetHRZone: Int? = base?.targetHeartRateZone
        var reasoning = ""
        var confidence = 70

        // Check for compound fatigue first (highest priority override)
        let hasCompoundFatigue = fatigue.contains { $0.type == .compoundFatigue }
        let hasSignificantFatigue = fatigue.contains { $0.severity == .significant }

        if hasCompoundFatigue || hasSignificantFatigue {
            recommendedType = .rest
            intensity = .easy
            distanceKm = 0
            elevationGainM = 0
            duration = 0
            targetHRZone = nil
            reasoning = "Multiple fatigue signals detected. A rest day will help your body recover."
            confidence = 90
        } else if let readinessStatus = readiness?.status {
            switch readinessStatus {
            case .needsRest:
                recommendedType = .rest
                intensity = .easy
                distanceKm = 0
                elevationGainM = 0
                duration = 0
                targetHRZone = nil
                reasoning = "Readiness is very low. Take a complete rest day."
                confidence = 85

            case .fatigued:
                if intensity == .hard || intensity == .maxEffort
                    || recommendedType == .intervals || recommendedType == .tempo {
                    recommendedType = .recovery
                    intensity = .easy
                    distanceKm = min(distanceKm, 8.0)
                    elevationGainM = min(elevationGainM, 100)
                    duration = min(duration, 3600)
                    targetHRZone = 1
                    reasoning = "Readiness is low. Swapped to an easy recovery run to manage fatigue."
                    confidence = 80
                } else {
                    distanceKm *= 0.8
                    duration *= 0.8
                    reasoning = "Readiness is below optimal. Reduced volume slightly."
                    confidence = 75
                }

            case .moderate:
                if intensity == .maxEffort {
                    intensity = .hard
                    reasoning = "Readiness is moderate. Reduced from max effort to hard."
                    confidence = 70
                } else if intensity == .hard {
                    distanceKm *= 0.9
                    duration *= 0.9
                    reasoning = "Readiness is moderate. Slightly reduced volume for today's hard session."
                    confidence = 70
                } else {
                    reasoning = "Readiness is moderate. Keeping planned session as-is."
                    confidence = 65
                }

            case .ready:
                reasoning = "Readiness is good. Execute the planned session."
                confidence = 75

            case .primed:
                if (recommendedType == .recovery || intensity == .easy)
                    && phase != .taper && phase != .recovery {
                    recommendedType = .tempo
                    intensity = .moderate
                    distanceKm = max(distanceKm, 8.0)
                    duration = max(duration, 3000)
                    targetHRZone = 3
                    reasoning = "Readiness is excellent. Upgraded to a tempo session to capitalize on your fitness."
                    confidence = 75
                } else {
                    reasoning = "Readiness is excellent. Great day to push the planned session."
                    confidence = 80
                }
            }
        } else {
            reasoning = "No readiness data available. Following the planned session."
            confidence = 50
        }

        // Phase constraints (override bad recommendations)
        applyPhaseConstraints(
            phase: phase,
            type: &recommendedType,
            intensity: &intensity,
            reasoning: &reasoning
        )

        // Weather adjustments
        if let weather {
            applyWeatherAdjustments(
                weather: weather,
                intensity: &intensity,
                distanceKm: &distanceKm,
                duration: &duration,
                reasoning: &reasoning
            )
        }

        // Time constraint
        if let availableMinutes = input.availableTimeMinutes {
            let availableSeconds = TimeInterval(availableMinutes * 60)
            if duration > availableSeconds {
                let ratio = availableSeconds / duration
                distanceKm *= ratio
                elevationGainM *= ratio
                duration = availableSeconds
                reasoning += " Scaled to fit available time (\(availableMinutes) min)."
            }
        }

        return OptimalSession(
            id: UUID(),
            recommendedType: recommendedType,
            distanceKm: max(0, distanceKm.rounded(toPlaces: 1)),
            elevationGainM: max(0, elevationGainM.rounded(toPlaces: 0)),
            duration: max(0, duration),
            intensity: intensity,
            targetHeartRateZone: targetHRZone,
            reasoning: reasoning,
            replacesSessionId: base?.id,
            confidencePercent: confidence,
            phase: phase
        )
    }

    // MARK: - Phase Constraints

    private static func applyPhaseConstraints(
        phase: TrainingPhase,
        type: inout SessionType,
        intensity: inout Intensity,
        reasoning: inout String
    ) {
        switch phase {
        case .taper:
            if type == .intervals || intensity == .maxEffort {
                type = .tempo
                intensity = .moderate
                reasoning += " Adjusted for taper phase — no intervals or max effort."
            }
        case .recovery:
            if intensity == .hard || intensity == .maxEffort {
                intensity = .easy
                type = .recovery
                reasoning += " Recovery phase — keeping intensity easy."
            }
        case .race:
            if type != .rest {
                intensity = .easy
                reasoning += " Race week — keeping effort easy."
            }
        case .base:
            if intensity == .maxEffort {
                intensity = .hard
                reasoning += " Base phase — capped intensity."
            }
        case .build, .peak:
            break
        }
    }

    // MARK: - Weather Adjustments

    private static func applyWeatherAdjustments(
        weather: WeatherSnapshot,
        intensity: inout Intensity,
        distanceKm: inout Double,
        duration: inout TimeInterval,
        reasoning: inout String
    ) {
        // Heat adjustment
        if weather.temperatureCelsius > 30 {
            if intensity == .hard || intensity == .maxEffort {
                intensity = .moderate
                reasoning += " Reduced intensity due to high heat (\(Int(weather.temperatureCelsius))°C)."
            }
            distanceKm *= 0.85
            duration *= 0.85
        }

        // Strong wind
        if weather.windSpeedKmh > 40 {
            distanceKm *= 0.9
            reasoning += " Reduced distance due to strong winds."
        }

        // Cold
        if weather.temperatureCelsius < -5 {
            duration *= 0.9
            reasoning += " Shortened duration due to extreme cold."
        }
    }
}

// MARK: - Double Extension

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}
