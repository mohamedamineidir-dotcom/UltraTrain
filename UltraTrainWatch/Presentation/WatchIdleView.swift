import SwiftUI

struct WatchIdleView: View {
    let isPhoneReachable: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.system(size: 40))
                .foregroundStyle(.green)

            Text("UltraTrain")
                .font(.headline)

            Text("Start a run on your iPhone to see live metrics here.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if !isPhoneReachable {
                Label("iPhone not connected", systemImage: "iphone.slash")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
    }
}
