import SwiftUI

struct StravaStatusSection: View {
    let run: CompletedRun
    let stravaConnected: Bool
    let stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)?

    @State private var uploadStatus: StravaUploadStatus = .idle
    @State private var queueStatus: StravaQueueItemStatus?

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if run.isStravaImport {
                importedBadge
            } else if run.stravaActivityId != nil {
                uploadedBadge
            } else {
                uploadControls
            }
        }
    }

    // MARK: - Imported

    private var importedBadge: some View {
        VStack(spacing: Theme.Spacing.sm) {
            stravaBadge(icon: "arrow.down.circle.fill", text: "Imported from Strava", color: .orange)
            if let activityId = run.stravaActivityId {
                stravaLink(activityId: activityId)
            }
        }
    }

    // MARK: - Uploaded

    private var uploadedBadge: some View {
        VStack(spacing: Theme.Spacing.sm) {
            stravaBadge(icon: "checkmark.circle.fill", text: "Uploaded to Strava", color: .green)
            if let activityId = run.stravaActivityId {
                stravaLink(activityId: activityId)
            }
        }
    }

    // MARK: - Upload Controls

    @ViewBuilder
    private var uploadControls: some View {
        switch uploadStatus {
        case .idle:
            if queueStatus == .pending {
                stravaBadge(icon: "clock.fill", text: "Upload pending", color: .orange)
            } else if queueStatus == .failed {
                stravaBadge(icon: "exclamationmark.triangle.fill", text: "Upload failed", color: .red)
                Button("Retry Upload") { uploadToStrava() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            } else if stravaConnected && !run.gpsTrack.isEmpty {
                uploadButton
            }
        case .uploading, .processing:
            HStack(spacing: Theme.Spacing.sm) {
                ProgressView()
                Text("Uploading to Strava...")
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.md).fill(Color.orange.opacity(0.1)))
        case .success:
            stravaBadge(icon: "checkmark.circle.fill", text: "Uploaded to Strava", color: .green)
        case .failed(let reason):
            VStack(spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.Colors.warning)
                    Text("Upload failed: \(reason)")
                        .font(.caption)
                }
                Button("Retry") { uploadToStrava() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.md).fill(Theme.Colors.warning.opacity(0.1)))
        }
    }

    private var uploadButton: some View {
        Button { uploadToStrava() } label: {
            Label("Upload to Strava", systemImage: "arrow.up.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
        }
        .buttonStyle(.bordered)
        .tint(.orange)
        .task {
            queueStatus = await stravaUploadQueueService?.getQueueStatus(forRunId: run.id)
        }
    }

    // MARK: - Helpers

    private func stravaBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon).foregroundStyle(color)
            Text(text).font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.md).fill(color.opacity(0.1)))
    }

    private func stravaLink(activityId: Int) -> some View {
        Link(destination: URL(string: "https://www.strava.com/activities/\(activityId)")!) {
            Label("View on Strava", systemImage: "arrow.up.right.square")
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
    }

    private func uploadToStrava() {
        guard let queueService = stravaUploadQueueService else { return }
        uploadStatus = .uploading
        Task {
            do {
                try await queueService.enqueueUpload(runId: run.id)
                await queueService.processQueue()
                if let status = await queueService.getQueueStatus(forRunId: run.id),
                   status == .completed {
                    uploadStatus = .success(activityId: 0)
                } else {
                    uploadStatus = .idle
                    queueStatus = await queueService.getQueueStatus(forRunId: run.id)
                }
            } catch {
                uploadStatus = .failed(reason: error.localizedDescription)
            }
        }
    }
}
