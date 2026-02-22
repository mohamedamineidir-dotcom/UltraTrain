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
                    id: UUID(), title: "Foam Rolling & Stretching",
                    description: "High muscle soreness detected. Spend 15-20 minutes on foam rolling and dynamic stretching before any activity.",
                    iconName: "figure.flexibility", priority: .high
                ))
            } else if checkIn.muscleSoreness == 3 {
                recommendations.append(RecoveryRecommendation(
                    id: UUID(), title: "Light Stretching",
                    description: "Moderate soreness. A gentle stretching routine will help with recovery.",
                    iconName: "figure.cooldown", priority: .medium
                ))
            }

            if checkIn.perceivedEnergy <= 2 {
                recommendations.append(RecoveryRecommendation(
                    id: UUID(), title: "Rest or Easy Recovery Run",
                    description: "Low energy levels. Consider taking a rest day or a very easy 20-30 min recovery jog.",
                    iconName: "bed.double", priority: .high
                ))
            }

            if checkIn.mood <= 2 {
                recommendations.append(RecoveryRecommendation(
                    id: UUID(), title: "Mental Break",
                    description: "Low mood can impact performance. Consider cross-training, yoga, or a nature walk instead of a hard session.",
                    iconName: "brain.head.profile", priority: .medium
                ))
            }

            if checkIn.sleepQualitySubjective <= 2 {
                recommendations.append(RecoveryRecommendation(
                    id: UUID(), title: "Prioritize Sleep Tonight",
                    description: "Poor sleep quality. Aim for 8+ hours tonight. Avoid screens 1 hour before bed.",
                    iconName: "moon.zzz", priority: .medium
                ))
            }
        }

        if let recovery = recoveryScore {
            if recovery.status == .critical || recovery.status == .poor {
                recommendations.append(RecoveryRecommendation(
                    id: UUID(), title: "Full Rest Day Recommended",
                    description: "Your recovery score is \(recovery.status == .critical ? "critical" : "low"). Take a complete rest day to avoid overtraining.",
                    iconName: "pause.circle", priority: .high
                ))
            }

            if recovery.sleepQualityScore < 40 {
                recommendations.append(RecoveryRecommendation(
                    id: UUID(), title: "Improve Sleep Routine",
                    description: "Sleep quality has been declining. Maintain a consistent bedtime and cool sleeping environment.",
                    iconName: "moon.stars", priority: .medium
                ))
            }
        }

        if let readiness, readiness.overallScore < 40 {
            recommendations.append(RecoveryRecommendation(
                id: UUID(), title: "Reduce Training Intensity",
                description: "Low readiness score. Swap any planned hard session for an easy effort or rest day.",
                iconName: "arrow.down.circle", priority: .high
            ))
        }

        if recommendations.isEmpty {
            recommendations.append(RecoveryRecommendation(
                id: UUID(), title: "All Systems Go",
                description: "You're well recovered. Train as planned and stay hydrated!",
                iconName: "checkmark.circle", priority: .low
            ))
        }

        return recommendations.sorted { $0.priority > $1.priority }
    }
}
