import SwiftUI

struct ReplayControlsBar: View {
    let isPlaying: Bool
    let currentSpeed: Double
    let onTogglePlayPause: () -> Void
    let onSpeedChanged: (Double) -> Void

    private let speeds: [Double] = [1, 2, 5, 10]

    var body: some View {
        HStack(spacing: Theme.Spacing.lg) {
            Picker("Speed", selection: Binding(
                get: { currentSpeed },
                set: { onSpeedChanged($0) }
            )) {
                ForEach(speeds, id: \.self) { speed in
                    Text("\(Int(speed))x").tag(speed)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 200)
            .accessibilityIdentifier("replayControls.speedPicker")

            Button(action: onTogglePlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Theme.Colors.primary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .accessibilityLabel(isPlaying ? "Pause" : "Play")
            .accessibilityIdentifier("replayControls.playPauseButton")
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
}
