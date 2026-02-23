import SwiftUI

private struct SyncServiceKey: EnvironmentKey {
    static let defaultValue: (any SyncQueueServiceProtocol)? = nil
}

extension EnvironmentValues {
    var syncService: (any SyncQueueServiceProtocol)? {
        get { self[SyncServiceKey.self] }
        set { self[SyncServiceKey.self] = newValue }
    }
}
