import SwiftUI

struct WatchContentView: View {
    let connectivityService: WatchConnectivityService

    private var isRunActive: Bool {
        guard let data = connectivityService.runData else { return false }
        return data.runState != "notStarted" && data.runState != "finished"
    }

    var body: some View {
        if let data = connectivityService.runData, isRunActive {
            WatchActiveRunView(
                runData: data,
                onPause: { connectivityService.sendCommand(.pause) },
                onResume: { connectivityService.sendCommand(.resume) },
                onStop: { connectivityService.sendCommand(.stop) },
                onDismissReminder: { connectivityService.sendCommand(.dismissReminder) }
            )
        } else {
            WatchIdleView(isPhoneReachable: connectivityService.isPhoneReachable)
        }
    }
}
