import Foundation
import os

final class ExportService: ExportServiceProtocol, @unchecked Sendable {

    private let gpxExporter = GPXExporter()
    private let csvExporter = CSVExporter()
    private let fileManager = FileManager.default

    func exportRunAsGPX(_ run: CompletedRun) async throws -> URL {
        let content = gpxExporter.exportToGPX(run: run)
        let filename = "UltraTrain_Run_\(dateString(run.date)).gpx"
        return try writeToTempFile(content: content, filename: filename)
    }

    func exportRunsAsCSV(_ runs: [CompletedRun]) async throws -> URL {
        let content = csvExporter.exportRunsToCSV(runs)
        let filename = "UltraTrain_Runs_\(dateString(Date.now)).csv"
        return try writeToTempFile(content: content, filename: filename)
    }

    func exportRunTrackAsCSV(_ run: CompletedRun) async throws -> URL {
        let content = csvExporter.exportTrackPointsToCSV(run)
        let filename = "UltraTrain_Track_\(dateString(run.date)).csv"
        return try writeToTempFile(content: content, filename: filename)
    }

    // MARK: - Private

    private func writeToTempFile(content: String, filename: String) throws -> URL {
        cleanupOldTempFiles()

        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("UltraTrainExport", isDirectory: true)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let fileURL = tempDir.appendingPathComponent(filename)
        guard let data = content.data(using: .utf8) else {
            throw DomainError.exportFailed(reason: "Failed to encode content as UTF-8")
        }

        try data.write(to: fileURL, options: .atomic)
        Logger.export.info("Exported file: \(filename)")
        return fileURL
    }

    private func cleanupOldTempFiles() {
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("UltraTrainExport", isDirectory: true)
        guard let files = try? fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }

        let oneHourAgo = Date.now.addingTimeInterval(-3600)
        for file in files {
            guard let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                  let created = attributes[.creationDate] as? Date,
                  created < oneHourAgo else { continue }
            try? fileManager.removeItem(at: file)
        }
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
