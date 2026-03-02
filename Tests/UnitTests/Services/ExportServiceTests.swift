import Foundation
import Testing
@testable import UltraTrain

@Suite("ExportService Tests")
struct ExportServiceTests {

    private let service = ExportService()

    private func makeRun(
        date: Date = Date(timeIntervalSince1970: 1_700_000_000),
        distanceKm: Double = 10.0,
        trackPoints: [TrackPoint] = [],
        splits: [Split] = []
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: date,
            distanceKm: distanceKm,
            elevationGainM: 200,
            elevationLossM: 180,
            duration: 3600,
            averageHeartRate: 145,
            maxHeartRate: 170,
            averagePaceSecondsPerKm: 360,
            gpsTrack: trackPoints,
            splits: splits,
            pausedDuration: 60
        )
    }

    private func makeTrackPoint(
        lat: Double = 45.5,
        lon: Double = 6.5,
        alt: Double = 1000,
        timestamp: Date = .now,
        heartRate: Int? = 150
    ) -> TrackPoint {
        TrackPoint(
            latitude: lat,
            longitude: lon,
            altitudeM: alt,
            timestamp: timestamp,
            heartRate: heartRate
        )
    }

    // MARK: - GPX Export

    @Test("exportRunAsGPX creates a file with .gpx extension")
    func exportGPXCreatesFile() async throws {
        let trackPoints = [
            makeTrackPoint(lat: 45.5, lon: 6.5),
            makeTrackPoint(lat: 45.51, lon: 6.51)
        ]
        let run = makeRun(trackPoints: trackPoints)

        let url = try await service.exportRunAsGPX(run)

        #expect(url.pathExtension == "gpx")
        #expect(FileManager.default.fileExists(atPath: url.path))

        // Clean up
        try? FileManager.default.removeItem(at: url)
    }

    @Test("exportRunAsGPX filename contains formatted date")
    func exportGPXFilenameContainsDate() async throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let run = makeRun(date: date)

        let url = try await service.exportRunAsGPX(run)

        // The service uses a DateFormatter with "yyyy-MM-dd" in the local timezone,
        // so we compute the expected date string the same way.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let expectedDateString = formatter.string(from: date)

        #expect(url.lastPathComponent.contains(expectedDateString))
        #expect(url.lastPathComponent.hasPrefix("UltraTrain_Run_"))

        try? FileManager.default.removeItem(at: url)
    }

    @Test("exportRunAsGPX produces valid GPX content with track points")
    func exportGPXContentIncludesTrackPoints() async throws {
        let trackPoints = [
            makeTrackPoint(lat: 45.123, lon: 6.456, alt: 1200, heartRate: 155)
        ]
        let run = makeRun(trackPoints: trackPoints)

        let url = try await service.exportRunAsGPX(run)
        let content = try String(contentsOf: url, encoding: .utf8)

        #expect(content.contains("<gpx"))
        #expect(content.contains("45.123"))
        #expect(content.contains("6.456"))
        #expect(content.contains("<ele>1200.0</ele>"))
        #expect(content.contains("<gpxtpx:hr>155</gpxtpx:hr>"))

        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - CSV Export

    @Test("exportRunsAsCSV creates a file with .csv extension")
    func exportCSVCreatesFile() async throws {
        let runs = [makeRun(), makeRun()]

        let url = try await service.exportRunsAsCSV(runs)

        #expect(url.pathExtension == "csv")
        #expect(FileManager.default.fileExists(atPath: url.path))

        try? FileManager.default.removeItem(at: url)
    }

    @Test("exportRunsAsCSV includes header and all runs")
    func exportCSVContainsAllRuns() async throws {
        let runs = [
            makeRun(distanceKm: 10.0),
            makeRun(distanceKm: 21.1),
            makeRun(distanceKm: 42.2)
        ]

        let url = try await service.exportRunsAsCSV(runs)
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }

        // 1 header + 3 data rows
        #expect(lines.count == 4)
        #expect(lines[0].contains("Date"))
        #expect(lines[0].contains("Distance"))
        #expect(content.contains("10.00"))
        #expect(content.contains("21.10"))
        #expect(content.contains("42.20"))

        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Track Points CSV

    @Test("exportRunTrackAsCSV includes track point data")
    func exportTrackCSVContainsPoints() async throws {
        let trackPoints = [
            makeTrackPoint(lat: 45.0, lon: 6.0, alt: 1000, heartRate: 140),
            makeTrackPoint(lat: 45.1, lon: 6.1, alt: 1100, heartRate: 155)
        ]
        let run = makeRun(trackPoints: trackPoints)

        let url = try await service.exportRunTrackAsCSV(run)
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }

        // 1 header + 2 data rows
        #expect(lines.count == 3)
        #expect(lines[0].contains("Latitude"))
        #expect(content.contains("45.0"))
        #expect(content.contains("45.1"))

        try? FileManager.default.removeItem(at: url)
    }

    @Test("exportRunTrackAsCSV with empty track produces header only")
    func exportTrackCSVEmptyTrack() async throws {
        let run = makeRun(trackPoints: [])

        let url = try await service.exportRunTrackAsCSV(run)
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }

        #expect(lines.count == 1)
        #expect(lines[0].contains("Timestamp"))

        try? FileManager.default.removeItem(at: url)
    }
}
