import SwiftUI
import os

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
                    await requestInitialPermissions()
                }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if let vm = watchRunViewModel {
            WatchContentView(
                connectivityService: connectivityService,
                locationService: locationService,
                watchRunViewModel: vm
            )
        } else {
            ProgressView()
        }
    }

    // MARK: - Permissions

    private func requestInitialPermissions() async {
        if locationService.authStatus == .notDetermined {
            locationService.requestAuthorization()
            Logger.watch.info("Requested location authorization on first launch")
        }

        if healthKitService.authStatus == .notDetermined {
            do {
                try await healthKitService.requestAuthorization()
                Logger.watch.info("Requested HealthKit authorization on first launch")
            } catch {
                Logger.watch.error("HealthKit authorization failed: \(error)")
            }
        }
    }
}
