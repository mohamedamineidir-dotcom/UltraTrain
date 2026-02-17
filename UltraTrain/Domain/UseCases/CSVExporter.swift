import Foundation

struct CSVExporter: Sendable {

    func exportRunsToCSV(_ runs: [CompletedRun]) -> String {
        var csv = "Date,Distance (km),Duration (s),Moving Time (s),Elevation Gain (m),Elevation Loss (m),Avg Pace (s/km),Avg HR,Max HR,Notes\n"

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        for run in runs {
            let date = formatter.string(from: run.date)
            let avgHR = run.averageHeartRate.map(String.init) ?? ""
            let maxHR = run.maxHeartRate.map(String.init) ?? ""
            let notes = escapeCSV(run.notes ?? "")
            let movingTime = String(format: "%.0f", run.duration)
            let totalTime = String(format: "%.0f", run.totalDuration)

            csv += "\(date),"
            csv += "\(String(format: "%.2f", run.distanceKm)),"
            csv += "\(totalTime),"
            csv += "\(movingTime),"
            csv += "\(String(format: "%.0f", run.elevationGainM)),"
            csv += "\(String(format: "%.0f", run.elevationLossM)),"
            csv += "\(String(format: "%.0f", run.averagePaceSecondsPerKm)),"
            csv += "\(avgHR),"
            csv += "\(maxHR),"
            csv += "\(notes)\n"
        }

        return csv
    }

    func exportTrackPointsToCSV(_ run: CompletedRun) -> String {
        var csv = "Timestamp,Latitude,Longitude,Altitude (m),Heart Rate\n"

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for point in run.gpsTrack {
            let timestamp = formatter.string(from: point.timestamp)
            let hr = point.heartRate.map(String.init) ?? ""
            csv += "\(timestamp),\(point.latitude),\(point.longitude),\(String(format: "%.1f", point.altitudeM)),\(hr)\n"
        }

        return csv
    }

    // MARK: - Private

    private func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}
