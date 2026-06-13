import Foundation

enum RecoveryRecommendationEngine {

    static func recommend(
        readiness: ReadinessScore?,
        checkIn: MorningCheckIn?,
        recoveryScore: RecoveryScore?
    ) -> [RecoveryRecommendation] {
        var recommendations: [RecoveryRecommendation] = []

        if let checkIn {
            if checkIn.muscleSoreness >= 4 {
                recommendations.append(RecoveryRecommendation(
                    id: UUID(), title: String(localized: "rre.foam.title", defaultValue: "Foam Rolling & Stretching"),
                    description: String(localized: "rre.foam.desc", defaultValue: "High muscle soreness detected. Spend 15-20 minutes on foam rolling and dynamic stretching before any activity."),
                    iconName: "figure.flexibility", priority: .high
                ))
            } else if checkIn.muscleSoreness == 3 {
                recommendations.append(RecoveryRecommendation(
                    id: UUID(), title: String(localized: "rre.lightStretch.title", defaultValue: "Light Stretching"),
                    description: String(localized: "rre.lightStretch.desc", defaultValue: "Moderate soreness. A gentle stretching routine will help with recovery."),
                    iconName: "figure.cooldown", priority: .medium
                ))
            }

            if checkIn.perceivedEnergy <= 2 {
                recommendations.append(RecoveryRecommendation(
                    id: UUID(), title: String(localized: "rre.restEasy.title", defaultValue: "Rest or Easy Recovery Run"),
                    description: String(localized: "rre.restEasy.desc", defaultValue: "Low energy levels. Consider taking a rest day or a very easy 20-30 min recovery jog."),
                    iconName: "bed.double", priority: .high
                ))
            }

            if checkIn.mood <= 2 {
                recommendations.append(RecoveryRecommendation(
                    id: UUID(), title: String(localized: "rre.mental.title", defaultValue: "Mental Break"),
                    description: String(localized: "rre.mental.desc", defaultValue: "Low mood can impact performance. Consider cross-training, yoga, or a nature walk instead of a hard session."),
                    iconName: "brain.head.profile", priority: .medium
                ))
            }

            if checkIn.sleepQualitySubjective <= 2 {
                recommendations.append(RecoveryRecommendation(
                    id: UUID(), title: String(localized: "rre.sleepTonight.title", defaultValue: "Prioritize Sleep Tonight"),
                    description: String(localized: "rre.sleepTonight.desc", defaultValue: "Poor sleep quality. Aim for 8+ hours tonight. Avoid screens 1 hour before bed."),
                    iconName: "moon.zzz", priority: .medium
                ))
            }
        }

        if let recovery = recoveryScore {
            if recovery.status == .critical || recovery.status == .poor {
                let scoreWord = recovery.status == .critical
                    ? String(localized: "rre.word.critical", defaultValue: "critical")
                    : String(localized: "rre.word.low", defaultValue: "low")
                recommendations.append(RecoveryRecommendation(
                    id: UUID(), title: String(localized: "rre.fullRest.title", defaultValue: "Full Rest Day Recommended"),
                    description: String(localized: "rre.fullRest.desc", defaultValue: "Your recovery score is \(scoreWord). Take a complete rest day to avoid overtraining."),
                    iconName: "pause.circle", priority: .high
                ))
            }

            if recovery.sleepQualityScore < 40 {
                recommendations.append(RecoveryRecommendation(
                    id: UUID(), title: String(localized: "rre.improveSleep.title", defaultValue: "Improve Sleep Routine"),
                    description: String(localized: "rre.improveSleep.desc", defaultValue: "Sleep quality has been declining. Maintain a consistent bedtime and cool sleeping environment."),
                    iconName: "moon.stars", priority: .medium
                ))
            }
        }

        if let readiness, readiness.overallScore < 40 {
            recommendations.append(RecoveryRecommendation(
                id: UUID(), title: String(localized: "rre.reduceIntensity.title", defaultValue: "Reduce Training Intensity"),
                description: String(localized: "rre.reduceIntensity.desc", defaultValue: "Low readiness score. Swap any planned hard session for an easy effort or rest day."),
                iconName: "arrow.down.circle", priority: .high
            ))
        }

        if recommendations.isEmpty {
            recommendations.append(RecoveryRecommendation(
                id: UUID(), title: String(localized: "rre.allGood.title", defaultValue: "All Systems Go"),
                description: String(localized: "rre.allGood.desc", defaultValue: "You're well recovered. Train as planned and stay hydrated!"),
                iconName: "checkmark.circle", priority: .low
            ))
        }

        return recommendations.sorted { $0.priority > $1.priority }
    }
}
