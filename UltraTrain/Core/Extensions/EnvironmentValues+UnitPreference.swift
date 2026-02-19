import SwiftUI

private struct UnitPreferenceKey: EnvironmentKey {
    static let defaultValue: UnitPreference = .metric
}

extension EnvironmentValues {
    var unitPreference: UnitPreference {
        get { self[UnitPreferenceKey.self] }
        set { self[UnitPreferenceKey.self] = newValue }
    }
}
