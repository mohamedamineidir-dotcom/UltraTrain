import SwiftUI

private struct NetworkMonitorKey: EnvironmentKey {
    static let defaultValue: NetworkMonitor? = nil
}

extension EnvironmentValues {
    var networkMonitor: NetworkMonitor? {
        get { self[NetworkMonitorKey.self] }
        set { self[NetworkMonitorKey.self] = newValue }
    }
}
