import Foundation

enum ReadinessCalculator {

    static func calculate(
        recoveryScore: RecoveryScore,
        hrvTrend: HRVAnalyzer.HRVTrend?,
        fitnessSnapshot: FitnessSnapshot?
    ) -> ReadinessScore {
        let recoveryComponent = recoveryScore.overallScore

        let hrvComponent: Int
        let trainingLoadComponent: Int

        if let hrvTrend {
            hrvComponent = HRVAnalyzer.hrvScore(trend: hrvTrend)
            trainingLoadComponent = trainingLoadScore(fitnessSnapshot)

            let overall = Int(
                Double(recoveryComponent) * 0.40
                + Double(hrvComponent) * 0.30
                + Double(trainingLoadComponent) * 0.30
            )
            let clamped = max(0, min(100, overall))

            return ReadinessScore(
                overallScore: clamped,
                recoveryComponent: recoveryComponent,
                hrvComponent: hrvComponent,
                trainingLoadComponent: trainingLoadComponent,
                status: statusFor(score: clamped),
                sessionRecommendation: recommendationFor(score: clamped)
            )
        } else {
            hrvComponent = 0
            trainingLoadComponent = trainingLoadScore(fitnessSnapshot)

            let overall = Int(
                Double(recoveryComponent) * 0.55
                + Double(trainingLoadComponent) * 0.45
            )
            let clamped = max(0, min(100, overall))

            return ReadinessScore(
                overallScore: clamped,
                recoveryComponent: recoveryComponent,
                hrvComponent: hrvComponent,
                trainingLoadComponent: trainingLoadComponent,
                status: statusFor(score: clamped),
                sessionRecommendation: recommendationFor(score: clamped)
            )
        }
    }

    // MARK: - Private

    private static func trainingLoadScore(_ snapshot: FitnessSnapshot?) -> Int {
        guard let snapshot else { return 50 }
        let form = snapshot.form
        if form >= 10 { return 100 }
        if form <= -30 { return 0 }
        return Int(100 * (form + 30) / 40)
    }

    private static func statusFor(score: Int) -> ReadinessStatus {
        switch score {
        case 85...100: .primed
        case 70..<85: .ready
        case 50..<70: .moderate
        case 30..<50: .fatigued
        default: .needsRest
        }
    }

    private static func recommendationFor(score: Int) -> SessionIntensityRecommendation {
        switch score {
        case 85...100: .highIntensity
        case 70..<85: .moderateEffort
        case 50..<70: .easyOnly
        case 30..<50: .activeRecovery
        default: .restDay
        }
    }
}
