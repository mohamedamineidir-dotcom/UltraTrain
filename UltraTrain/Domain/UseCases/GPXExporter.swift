import Foundation

struct GPXExporter: Sendable {

    func exportToGPX(run: CompletedRun) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="UltraTrain iOS"
             xmlns="http://www.topografix.com/GPX/1/1"
             xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
          <metadata>
            <time>\(formatISO8601(run.date))</time>
          </metadata>
          <trk>
            <name>\(escapeXML(trackName(for: run)))</name>
            <trkseg>

        """

        for point in run.gpsTrack {
            xml += trackPointXML(point)
        }

        xml += """
            </trkseg>
          </trk>
        </gpx>

        """

        return xml
    }

    // MARK: - Private

    private func trackPointXML(_ point: TrackPoint) -> String {
        var xml = "      <trkpt lat=\"\(point.latitude)\" lon=\"\(point.longitude)\">\n"
        xml += "        <ele>\(String(format: "%.1f", point.altitudeM))</ele>\n"
        xml += "        <time>\(formatISO8601(point.timestamp))</time>\n"

        if let hr = point.heartRate {
            xml += "        <extensions>\n"
            xml += "          <gpxtpx:TrackPointExtension>\n"
            xml += "            <gpxtpx:hr>\(hr)</gpxtpx:hr>\n"
            xml += "          </gpxtpx:TrackPointExtension>\n"
            xml += "        </extensions>\n"
        }

        xml += "      </trkpt>\n"
        return xml
    }

    private func trackName(for run: CompletedRun) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Run - \(formatter.string(from: run.date))"
    }

    private func formatISO8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    private func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
