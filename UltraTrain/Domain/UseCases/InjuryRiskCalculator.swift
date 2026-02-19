import Foundation

enum InjuryRiskCalculator {

    static func assess(
        weeklyVolumes: [WeeklyVolume],
        currentACR: Double,
        monotony: Double
    ) -> [InjuryRiskAlert] {
        var alerts: [InjuryRiskAlert] = []

        if currentACR > 1.5 {
            alerts.append(InjuryRiskAlert(
                id: UUID(),
                type: .highACR,
                severity: .critical,
                message: "Acute-to-chronic ratio is \(String(format: "%.2f", currentACR)) — dangerously high.",
                recommendation: "Reduce training intensity and volume for the next 3-5 days. Focus on recovery runs or rest."
            ))
        }

        if let spike = detectVolumeSpike(weeklyVolumes) {
            alerts.append(InjuryRiskAlert(
                id: UUID(),
                type: .volumeSpike,
                severity: .warning,
                message: "Week-over-week volume increased by \(String(format: "%.0f", spike))%.",
                recommendation: "Increase weekly distance by no more than 10% to reduce injury risk. Consider dropping back next week."
            ))
        }

        if monotony > 2.0 {
            alerts.append(InjuryRiskAlert(
                id: UUID(),
                type: .highMonotony,
                severity: .warning,
                message: "Training monotony is \(String(format: "%.1f", monotony)) — too repetitive.",
                recommendation: "Vary session types and intensities. Mix easy, tempo, and long runs across the week."
            ))
        }

        if currentACR > 1.3 && monotony > 1.5 {
            alerts.append(InjuryRiskAlert(
                id: UUID(),
                type: .combinedStrain,
                severity: .critical,
                message: "High load combined with monotonous training pattern.",
                recommendation: "Take a recovery day immediately. When resuming, vary session types and reduce volume by 20-30%."
            ))
        }

        return alerts.sorted { $0.severity == .critical && $1.severity != .critical }
    }

    private static func detectVolumeSpike(_ volumes: [WeeklyVolume]) -> Double? {
        let active = volumes.filter { $0.runCount > 0 }
        guard active.count >= 2 else { return nil }

        let sorted = active.sorted { $0.weekStartDate < $1.weekStartDate }
        let current = sorted[sorted.count - 1].distanceKm
        let previous = sorted[sorted.count - 2].distanceKm

        guard previous > 0 else { return nil }

        let increasePercent = ((current - previous) / previous) * 100
        return increasePercent > 10 ? increasePercent : nil
    }
}
