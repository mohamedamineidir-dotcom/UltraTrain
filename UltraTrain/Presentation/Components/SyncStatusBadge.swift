import SwiftUI

struct SyncStatusBadge: View {
    let pendingCount: Int
    let failedCount: Int
    let isSyncing: Bool

    var body: some View {
        if failedCount > 0 {
            Label {
                Text("\(failedCount)")
            } icon: {
                Image(systemName: "exclamationmark.icloud.fill")
            }
            .font(.caption2)
            .foregroundStyle(.red)
            .accessibilityLabel("\(failedCount) sync failures")
        } else if isSyncing || pendingCount > 0 {
            Image(systemName: "icloud.and.arrow.up")
                .font(.caption)
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse, options: .repeating)
                .accessibilityLabel("Syncing \(pendingCount) items")
        }
    }
}
