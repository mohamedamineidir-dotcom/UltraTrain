import SwiftUI

@main
struct UltraTrainWatchApp: App {
    private let connectivityService = WatchConnectivityService()

    var body: some Scene {
        WindowGroup {
            WatchContentView(connectivityService: connectivityService)
                .task {
                    connectivityService.activate()
                }
        }
    }
}
