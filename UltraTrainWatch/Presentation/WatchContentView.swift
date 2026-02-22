import SwiftUI

struct WatchContentView: View {
    let connectivityService: WatchConnectivityService
    let locationService: WatchLocationService
    let watchRunViewModel: WatchRunViewModel

    @State private var showRunSummary = false

    private var isPhoneRunActive: Bool {
        guard let data = connectivityService.runData else { return false }
        return data.runState != "notStarted" && data.runState != "finished"
    }

    private var isWatchRunActive: Bool {
        watchRunViewModel.runState == .running || watchRunViewModel.runState == .paused
    }

    var body: some View {
        Group {
            if let data = connectivityService.runData, isPhoneRunActive {
                WatchActiveRunView(
                    runData: data,
                    onPause: { connectivityService.sendCommand(.pause) },
                    onResume: { connectivityService.sendCommand(.resume) },
                    onStop: { connectivityService.sendCommand(.stop) },
                    onDismissReminder: { connectivityService.sendCommand(.dismissReminder) }
                )
            } else if isWatchRunActive {
                WatchStandaloneRunView(
                    viewModel: watchRunViewModel,
                    onStop: {
                        Task {
                            await watchRunViewModel.stopRun()
                            showRunSummary = true
                        }
                    }
                )
            } else {
                NavigationStack {
                    WatchHomeView(
                        sessionData: connectivityService.sessionData,
                        isPhoneReachable: connectivityService.isPhoneReachable,
                        runHistory: connectivityService.runHistory,
                        locationAuthStatus: locationService.authStatus,
                        onStartRun: {
                            watchRunViewModel.linkedSession = connectivityService.sessionData
                            Task {
                                await watchRunViewModel.startRun()
                            }
                        },
                        onRequestLocationPermission: {
                            locationService.requestAuthorization()
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showRunSummary) {
            WatchRunSummaryView(
                viewModel: watchRunViewModel,
                onDone: {
                    watchRunViewModel.syncCompletedRun()
                    showRunSummary = false
                }
            )
        }
    }
}
