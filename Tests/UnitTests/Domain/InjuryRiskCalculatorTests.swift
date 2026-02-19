import Foundation
import Testing
@testable import UltraTrain

@Suite("Injury Risk Calculator Tests")
struct InjuryRiskCalculatorTests {

    // MARK: - Helpers

    private func makeVolumes(distances: [Double]) -> [WeeklyVolume] {
        distances.enumerated().map { index, km in
            WeeklyVolume(
                weekStartDate: Date.now.adding(weeks: -(distances.count - 1 - index)),
                distanceKm: km,
                elevationGainM: km * 20,
                duration: km * 360,
                runCount: km > 0 ? 3 : 0
            )
        }
    }

    // MARK: - Tests

    @Test("All values normal produces no alerts")
    func normalValues() {
        let volumes = makeVolumes(distances: [40, 42, 44, 46])
        let alerts = InjuryRiskCalculator.assess(
            weeklyVolumes: volumes,
            currentACR: 1.1,
            monotony: 1.3
        )
        #expect(alerts.isEmpty)
    }

    @Test("High ACR produces critical alert")
    func highACR() {
        let volumes = makeVolumes(distances: [40, 45])
        let alerts = InjuryRiskCalculator.assess(
            weeklyVolumes: volumes,
            currentACR: 1.6,
            monotony: 1.0
        )

        let acrAlerts = alerts.filter { $0.type == .highACR }
        #expect(acrAlerts.count == 1)
        #expect(acrAlerts[0].severity == .critical)
    }

    @Test("Volume spike over 10% produces warning")
    func volumeSpike() {
        let volumes = makeVolumes(distances: [40, 50])
        let alerts = InjuryRiskCalculator.assess(
            weeklyVolumes: volumes,
            currentACR: 1.0,
            monotony: 1.0
        )

        let spikeAlerts = alerts.filter { $0.type == .volumeSpike }
        #expect(spikeAlerts.count == 1)
        #expect(spikeAlerts[0].severity == .warning)
    }

    @Test("Volume increase under 10% produces no spike alert")
    func noVolumeSpike() {
        let volumes = makeVolumes(distances: [40, 43])
        let alerts = InjuryRiskCalculator.assess(
            weeklyVolumes: volumes,
            currentACR: 1.0,
            monotony: 1.0
        )

        let spikeAlerts = alerts.filter { $0.type == .volumeSpike }
        #expect(spikeAlerts.isEmpty)
    }

    @Test("High monotony produces warning")
    func highMonotony() {
        let volumes = makeVolumes(distances: [40, 42])
        let alerts = InjuryRiskCalculator.assess(
            weeklyVolumes: volumes,
            currentACR: 1.0,
            monotony: 2.5
        )

        let monotonyAlerts = alerts.filter { $0.type == .highMonotony }
        #expect(monotonyAlerts.count == 1)
        #expect(monotonyAlerts[0].severity == .warning)
    }

    @Test("Combined strain produces critical alert")
    func combinedStrain() {
        let volumes = makeVolumes(distances: [40, 42])
        let alerts = InjuryRiskCalculator.assess(
            weeklyVolumes: volumes,
            currentACR: 1.4,
            monotony: 1.8
        )

        let combinedAlerts = alerts.filter { $0.type == .combinedStrain }
        #expect(combinedAlerts.count == 1)
        #expect(combinedAlerts[0].severity == .critical)
    }

    @Test("Critical alerts sorted before warnings")
    func alertSortOrder() {
        let volumes = makeVolumes(distances: [40, 50])
        let alerts = InjuryRiskCalculator.assess(
            weeklyVolumes: volumes,
            currentACR: 1.6,
            monotony: 2.5
        )

        #expect(!alerts.isEmpty)
        if alerts.count >= 2 {
            #expect(alerts[0].severity == .critical)
        }
    }
}
