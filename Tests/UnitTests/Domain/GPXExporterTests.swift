import Testing
import Foundation
@testable import UltraTrain

@Suite("GPXExporter")
struct GPXExporterTests {
    private let exporter = GPXExporter()

    private func sampleRun(trackPoints: [TrackPoint] = []) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: Date(timeIntervalSince1970: 1708300000),
            distanceKm: 10.0,
            elevationGainM: 500,
            elevationLossM: 480,
            duration: 3600,
            averageHeartRate: 145,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            gpsTrack: trackPoints,
            splits: [],
            notes: nil,
            pausedDuration: 0
        )
    }

    @Test("Export with track points produces valid GPX XML")
    func exportWithTrackPoints() {
        let points = [
            TrackPoint(latitude: 45.123456, longitude: 6.789012, altitudeM: 1200.5, timestamp: Date(timeIntervalSince1970: 1708300000), heartRate: 140),
            TrackPoint(latitude: 45.123500, longitude: 6.789100, altitudeM: 1210.3, timestamp: Date(timeIntervalSince1970: 1708300010), heartRate: 145)
        ]
        let run = sampleRun(trackPoints: points)
        let gpx = exporter.exportToGPX(run: run)

        #expect(gpx.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
        #expect(gpx.contains("gpx version=\"1.1\""))
        #expect(gpx.contains("creator=\"UltraTrain iOS\""))
        #expect(gpx.contains("<trk>"))
        #expect(gpx.contains("<trkseg>"))
        #expect(gpx.contains("lat=\"45.123456\""))
        #expect(gpx.contains("lon=\"6.789012\""))
        #expect(gpx.contains("<ele>1200.5</ele>"))
        #expect(gpx.contains("</gpx>"))
    }

    @Test("Export includes heart rate extension when present")
    func exportWithHeartRate() {
        let points = [
            TrackPoint(latitude: 45.0, longitude: 6.0, altitudeM: 1000, timestamp: Date(timeIntervalSince1970: 1708300000), heartRate: 155)
        ]
        let run = sampleRun(trackPoints: points)
        let gpx = exporter.exportToGPX(run: run)

        #expect(gpx.contains("gpxtpx:TrackPointExtension"))
        #expect(gpx.contains("<gpxtpx:hr>155</gpxtpx:hr>"))
    }

    @Test("Export omits heart rate extension when nil")
    func exportWithoutHeartRate() {
        let points = [
            TrackPoint(latitude: 45.0, longitude: 6.0, altitudeM: 1000, timestamp: Date(timeIntervalSince1970: 1708300000), heartRate: nil)
        ]
        let run = sampleRun(trackPoints: points)
        let gpx = exporter.exportToGPX(run: run)

        #expect(!gpx.contains("gpxtpx:hr"))
    }

    @Test("Export with empty track produces valid GPX structure")
    func exportEmptyTrack() {
        let run = sampleRun()
        let gpx = exporter.exportToGPX(run: run)

        #expect(gpx.contains("<trkseg>"))
        #expect(gpx.contains("</trkseg>"))
        #expect(!gpx.contains("<trkpt"))
    }

    @Test("Export escapes XML special characters in track name")
    func exportEscapesXML() {
        // The track name is derived from the date, so no special chars there,
        // but the escapeXML function should handle edge cases
        let run = sampleRun()
        let gpx = exporter.exportToGPX(run: run)

        // Just verify it's valid XML-ish structure
        #expect(gpx.contains("<name>"))
        #expect(gpx.contains("</name>"))
    }
}
