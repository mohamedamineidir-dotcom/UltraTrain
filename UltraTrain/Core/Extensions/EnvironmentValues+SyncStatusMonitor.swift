import SwiftUI

private struct SyncStatusMonitorKey: EnvironmentKey {
    static let defaultValue: SyncStatusMonitor? = nil
}

extension EnvironmentValues {
    var syncStatusMonitor: SyncStatusMonitor? {
        get { self[SyncStatusMonitorKey.self] }
        set { self[SyncStatusMonitorKey.self] = newValue }
    }
}
