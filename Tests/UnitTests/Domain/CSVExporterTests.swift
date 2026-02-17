import Testing
import Foundation
@testable import UltraTrain

@Suite("CSVExporter")
struct CSVExporterTests {
    private let exporter = CSVExporter()

    private func sampleRun(
        date: Date = Date(timeIntervalSince1970: 1708300000),
        notes: String? = nil
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: date,
            distanceKm: 12.5,
            elevationGainM: 600,
            elevationLossM: 580,
            duration: 4500,
            averageHeartRate: 148,
            maxHeartRate: 178,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            notes: notes,
            pausedDuration: 120
        )
    }

    @Test("Export runs CSV produces correct headers")
    func csvHeaders() {
        let csv = exporter.exportRunsToCSV([sampleRun()])
        let firstLine = csv.components(separatedBy: "\n").first ?? ""

        #expect(firstLine.contains("Date"))
        #expect(firstLine.contains("Distance (km)"))
        #expect(firstLine.contains("Duration (s)"))
        #expect(firstLine.contains("Elevation Gain (m)"))
        #expect(firstLine.contains("Avg HR"))
        #expect(firstLine.contains("Notes"))
    }

    @Test("Export multiple runs produces correct row count")
    func csvMultipleRows() {
        let runs = [sampleRun(), sampleRun(), sampleRun()]
        let csv = exporter.exportRunsToCSV(runs)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        #expect(lines.count == 4) // 1 header + 3 data rows
    }

    @Test("Export escapes commas in notes field")
    func csvEscapesCommas() {
        let run = sampleRun(notes: "Good run, felt strong")
        let csv = exporter.exportRunsToCSV([run])

        #expect(csv.contains("\"Good run, felt strong\""))
    }

    @Test("Export handles nil notes")
    func csvNilNotes() {
        let run = sampleRun(notes: nil)
        let csv = exporter.exportRunsToCSV([run])
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        let dataLine = lines[1]

        // Notes field should be empty (last field before newline)
        #expect(dataLine.hasSuffix(","))
    }

    @Test("Export track points CSV produces per-point data")
    func trackPointsCSV() {
        var run = sampleRun()
        run.gpsTrack = [
            TrackPoint(latitude: 45.0, longitude: 6.0, altitudeM: 1000, timestamp: Date(timeIntervalSince1970: 1708300000), heartRate: 140),
            TrackPoint(latitude: 45.1, longitude: 6.1, altitudeM: 1010, timestamp: Date(timeIntervalSince1970: 1708300010), heartRate: nil)
        ]
        let csv = exporter.exportTrackPointsToCSV(run)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        #expect(lines.count == 3) // 1 header + 2 data points
        #expect(lines[0].contains("Latitude"))
        #expect(lines[1].contains("45.0"))
    }
}
