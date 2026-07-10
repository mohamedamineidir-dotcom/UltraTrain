import SwiftUI

/// Apple requires any screen displaying WeatherKit data to show this mark,
/// linking to Apple's data-source legal page. Reads the weather service from
/// the environment so callers just drop it into a card's body with no wiring.
struct WeatherAttributionBadge: View {
    @Environment(\.weatherService) private var weatherService
    @Environment(\.colorScheme) private var colorScheme
    @State private var attribution: WeatherAttributionInfo?

    var body: some View {
        Group {
            if let attribution {
                Link(destination: attribution.legalPageURL) {
                    AsyncImage(url: markURL(for: attribution)) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFit().frame(height: 12)
                        }
                    }
                }
                .accessibilityLabel("Weather data attribution")
                .accessibilityHint("Opens Apple's weather data source information")
            }
        }
        .task {
            guard attribution == nil, let weatherService else { return }
            attribution = try? await weatherService.attribution()
        }
    }

    private func markURL(for attribution: WeatherAttributionInfo) -> URL {
        colorScheme == .dark ? attribution.combinedMarkDarkURL : attribution.combinedMarkLightURL
    }
}
