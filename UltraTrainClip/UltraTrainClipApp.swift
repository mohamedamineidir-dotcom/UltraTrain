import SwiftUI

@main
struct UltraTrainClipApp: App {
    @State private var raceId: String?

    var body: some Scene {
        WindowGroup {
            NutritionTimerView(raceId: raceId)
                .onContinueUserActivity(
                    NSUserActivityTypeBrowsingWeb
                ) { activity in
                    handleUserActivity(activity)
                }
        }
    }

    private func handleUserActivity(_ activity: NSUserActivity) {
        guard let url = activity.webpageURL else { return }
        let components = url.pathComponents.filter { $0 != "/" }
        // Expected: ["race", "<raceId>", "nutrition"]
        guard components.count >= 3,
              components[0] == "race",
              components[2] == "nutrition" else { return }
        raceId = components[1]
    }
}
