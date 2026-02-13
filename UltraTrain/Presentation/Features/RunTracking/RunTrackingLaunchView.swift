import SwiftUI

struct RunTrackingLaunchView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xl) {
                Spacer()
                Image(systemName: "figure.run")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.Colors.primary)
                Text("Ready to Run?")
                    .font(.title.bold())
                Text("Track your run with GPS, pace, and heart rate.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
                Button("Start Run") {
                    // TODO: Launch active run tracking
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                Spacer()
            }
            .padding()
            .navigationTitle("Run")
        }
    }
}
