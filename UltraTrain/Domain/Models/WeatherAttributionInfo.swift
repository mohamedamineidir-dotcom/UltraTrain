import Foundation

/// Apple requires any UI displaying WeatherKit data to show the official
/// "Weather" attribution mark linking to Apple's data-source legal page.
/// See: https://weatherkit.apple.com/legal-attribution.html
struct WeatherAttributionInfo: Sendable, Equatable {
    let legalPageURL: URL
    let combinedMarkLightURL: URL
    let combinedMarkDarkURL: URL
}
