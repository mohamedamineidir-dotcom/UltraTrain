import SwiftUI

@main
struct UltraTrainWatchApp: App {
    private let connectivityService = WatchConnectivityService()
    private let locationService = WatchLocationService()
    private let healthKitService = WatchHealthKitService()
    @State private var watchRunViewModel: WatchRunViewModel?

    var body: some Scene {
        WindowGroup {
            contentView
                .task {
                    connectivityService.activate()
                    watchRunViewModel = WatchRunViewModel(
                        locationService: locationService,
                        healthKitService: healthKitService,
                        connectivityService: connectivityService
                    )
                }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if let vm = watchRunViewModel {
            WatchContentView(
                connectivityService: connectivityService,
                watchRunViewModel: vm
            )
        } else {
            ProgressView()
        }
    }
}
