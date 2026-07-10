import SwiftUI

private struct WeatherServiceKey: EnvironmentKey {
    static let defaultValue: (any WeatherServiceProtocol)? = nil
}

extension EnvironmentValues {
    var weatherService: (any WeatherServiceProtocol)? {
        get { self[WeatherServiceKey.self] }
        set { self[WeatherServiceKey.self] = newValue }
    }
}
