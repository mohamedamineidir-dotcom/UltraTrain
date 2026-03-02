import Foundation
import Testing
@testable import UltraTrain

/// Tests for the shared types and logic that support WatchRunViewModel.
/// The WatchRunViewModel itself lives in the Watch extension target and is not
/// directly importable. These tests cover the underlying calculator, data models,
/// nutrition reminder scheduler, and HR zone calculator that the ViewModel uses.
@Suite("Watch Run ViewModel Supporting Logic Tests")
struct WatchRunViewModelTests {

    // MARK: - Formatted Duration

    @Test("formatDuration formats hours, minutes, seconds correctly")
    func formatDuration() {
        #expect(WatchRunCalculator.formatDuration(0) == "00:00")
        #expect(WatchRunCalculator.formatDuration(59) == "00:59")
        #expect(WatchRunCalculator.formatDuration(60) == "01:00")
        #expect(WatchRunCalculator.formatDuration(3661) == "1:01:01")
        #expect(WatchRunCalculator.formatDuration(7200) == "2:00:00")
    }

    // MARK: - Formatted Pace

    @Test("formatPace returns min:sec per km format")
    func formatPace() {
        // 5:00 /km = 300 seconds per km
        #expect(WatchRunCalculator.formatPace(300) == "5:00")
        // 6:30 /km = 390 seconds per km
        #expect(WatchRunCalculator.formatPace(390) == "6:30")
        // Zero or invalid returns placeholder
        #expect(WatchRunCalculator.formatPace(0) == "--:--")
        #expect(WatchRunCalculator.formatPace(.nan) == "--:--")
        #expect(WatchRunCalculator.formatPace(.infinity) == "--:--")
    }

    // MARK: - Average Pace Calculation

    @Test("averagePace calculates seconds per km from distance and duration")
    func averagePace() {
        // 10 km in 3600 seconds = 360 sec/km
        let pace = WatchRunCalculator.averagePace(distanceKm: 10, duration: 3600)
        #expect(pace == 360)

        // Zero distance returns 0 to avoid division by zero
        let zeroPace = WatchRunCalculator.averagePace(distanceKm: 0, duration: 3600)
        #expect(zeroPace == 0)
    }

    // MARK: - BuildCompletedRunData Shape

    @Test("WatchCompletedRunData encodes and decodes correctly")
    func completedRunDataCodable() throws {
        let trackPoints = [
            WatchTrackPoint(
                latitude: 45.0, longitude: 6.0, altitudeM: 1000,
                timestamp: Date(timeIntervalSince1970: 1_000_000), heartRate: 140
            ),
            WatchTrackPoint(
                latitude: 45.001, longitude: 6.001, altitudeM: 1020,
                timestamp: Date(timeIntervalSince1970: 1_000_060), heartRate: 150
            ),
        ]
        let splits = WatchRunCalculator.buildSplits(from: trackPoints)

        let runData = WatchCompletedRunData(
            runId: UUID(),
            date: .now,
            distanceKm: 15.5,
            elevationGainM: 800,
            elevationLossM: 200,
            duration: 5400,
            pausedDuration: 120,
            averageHeartRate: 145,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 348,
            trackPoints: trackPoints,
            splits: splits,
            linkedSessionId: UUID()
        )

        let encoded = try JSONEncoder().encode(runData)
        let decoded = try JSONDecoder().decode(WatchCompletedRunData.self, from: encoded)

        #expect(decoded.distanceKm == 15.5)
        #expect(decoded.elevationGainM == 800)
        #expect(decoded.pausedDuration == 120)
        #expect(decoded.averageHeartRate == 145)
        #expect(decoded.maxHeartRate == 175)
        #expect(decoded.trackPoints.count == 2)
        #expect(decoded.linkedSessionId != nil)
    }

    // MARK: - Elevation Changes

    @Test("Elevation changes are calculated from track points")
    func elevationChanges() {
        let points = [
            WatchTrackPoint(latitude: 0, longitude: 0, altitudeM: 100, timestamp: .now, heartRate: nil),
            WatchTrackPoint(latitude: 0, longitude: 0, altitudeM: 150, timestamp: .now, heartRate: nil),
            WatchTrackPoint(latitude: 0, longitude: 0, altitudeM: 120, timestamp: .now, heartRate: nil),
            WatchTrackPoint(latitude: 0, longitude: 0, altitudeM: 180, timestamp: .now, heartRate: nil),
        ]

        let changes = WatchRunCalculator.elevationChanges(points)

        // Gain: (150-100) + (180-120) = 50 + 60 = 110
        #expect(changes.gainM == 110)
        // Loss: (150-120) = 30
        #expect(changes.lossM == 30)
    }

    // MARK: - Nutrition Reminder Scheduler (used by ViewModel timer tick)

    @Test("Nutrition reminder scheduler returns next due reminder at elapsed time")
    func nutritionReminderScheduler() {
        let reminders = WatchNutritionReminderScheduler.buildDefaultSchedule(
            hydrationInterval: 600,  // 10 min
            fuelInterval: 1200,      // 20 min
            maxDuration: 3600
        )

        // At 0 seconds, nothing is due
        let noneYet = WatchNutritionReminderScheduler.nextDueReminder(in: reminders, at: 0)
        #expect(noneYet == nil)

        // At 600 seconds, the first hydration reminder should be due
        let first = WatchNutritionReminderScheduler.nextDueReminder(in: reminders, at: 600)
        #expect(first != nil)
        #expect(first?.type == .hydration)

        // At 1200 seconds, both hydration (600, 1200) and fuel (1200) are due
        // nextDueReminder returns the earliest un-dismissed one
        let atTwentyMin = WatchNutritionReminderScheduler.nextDueReminder(in: reminders, at: 1200)
        #expect(atTwentyMin != nil)
        #expect(atTwentyMin?.triggerTimeSeconds == 600)
    }
}
