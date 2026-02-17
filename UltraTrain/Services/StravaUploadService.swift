import Foundation
import os

final class StravaUploadService: StravaUploadServiceProtocol {

    private let authService: any StravaAuthServiceProtocol
    private let gpxExporter: GPXExporter
    private let session: URLSession

    init(
        authService: any StravaAuthServiceProtocol,
        gpxExporter: GPXExporter = GPXExporter(),
        session: URLSession = .shared
    ) {
        self.authService = authService
        self.gpxExporter = gpxExporter
        self.session = session
    }

    func uploadRun(_ run: CompletedRun) async throws -> Int {
        guard !run.gpsTrack.isEmpty else {
            throw DomainError.stravaUploadFailed(reason: "Run has no GPS data to upload")
        }

        let token = try await authService.getValidToken()
        let gpxString = gpxExporter.exportToGPX(run: run)

        guard let gpxData = gpxString.data(using: .utf8) else {
            throw DomainError.stravaUploadFailed(reason: "Failed to encode GPX data")
        }

        let uploadId = try await uploadGPX(data: gpxData, token: token, run: run)
        let activityId = try await pollUploadStatus(uploadId: uploadId, token: token)

        Logger.strava.info("Successfully uploaded run \(run.id) as Strava activity \(activityId)")
        return activityId
    }

    // MARK: - Upload

    private func uploadGPX(data: Data, token: String, run: CompletedRun) async throws -> Int {
        let url = URL(string: "\(AppConfiguration.Strava.apiBaseURL)/uploads")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        let body = buildMultipartBody(
            boundary: boundary,
            gpxData: data,
            run: run
        )
        request.httpBody = body

        let (responseData, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DomainError.stravaUploadFailed(reason: "Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            Logger.strava.error("Upload failed with status \(httpResponse.statusCode): \(message)")
            throw DomainError.stravaUploadFailed(
                reason: "Upload failed (HTTP \(httpResponse.statusCode))"
            )
        }

        let uploadResponse = try JSONDecoder().decode(StravaUploadResponse.self, from: responseData)
        Logger.strava.info("Upload created with ID \(uploadResponse.id)")
        return uploadResponse.id
    }

    // MARK: - Poll

    private func pollUploadStatus(uploadId: Int, token: String) async throws -> Int {
        let maxAttempts = 10
        let pollInterval: UInt64 = 2_000_000_000 // 2 seconds

        for attempt in 1...maxAttempts {
            try await Task.sleep(nanoseconds: pollInterval)

            let url = URL(string: "\(AppConfiguration.Strava.apiBaseURL)/uploads/\(uploadId)")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await session.data(for: request)
            let status = try JSONDecoder().decode(StravaUploadResponse.self, from: data)

            if let activityId = status.activityId {
                return activityId
            }

            if let error = status.error {
                throw DomainError.stravaUploadFailed(reason: error)
            }

            Logger.strava.debug("Upload poll attempt \(attempt)/\(maxAttempts) — status: \(status.status ?? "unknown")")
        }

        throw DomainError.stravaUploadFailed(reason: "Upload processing timed out")
    }

    // MARK: - Multipart

    private func buildMultipartBody(boundary: String, gpxData: Data, run: CompletedRun) -> Data {
        var body = Data()

        let fileName = "run_\(run.date.ISO8601Format()).gpx"
        let runName = "UltraTrain Run — \(String(format: "%.1f", run.distanceKm)) km"

        appendField(to: &body, boundary: boundary, name: "data_type", value: "gpx")
        appendField(to: &body, boundary: boundary, name: "name", value: runName)
        appendField(to: &body, boundary: boundary, name: "description", value: "Uploaded from UltraTrain iOS")
        appendField(to: &body, boundary: boundary, name: "activity_type", value: "trail_run")

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/gpx+xml\r\n\r\n".data(using: .utf8)!)
        body.append(gpxData)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }

    private func appendField(to body: inout Data, boundary: String, name: String, value: String) {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(value)\r\n".data(using: .utf8)!)
    }
}

// MARK: - Response Model

private struct StravaUploadResponse: Decodable {
    let id: Int
    let status: String?
    let activityId: Int?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case activityId = "activity_id"
        case error
    }
}
