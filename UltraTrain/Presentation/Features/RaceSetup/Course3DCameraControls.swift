import SwiftUI

struct Course3DCameraControls: View {
    @Binding var pitch: Double
    @Binding var heading: Double
    @Binding var distance: Double
    let isFlying: Bool
    let onFlyToggle: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            pitchSlider
            headingSlider
            zoomSlider
            flyAlongButton
        }
        .padding(Theme.Spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
    }

    // MARK: - Pitch

    private var pitchSlider: some View {
        HStack {
            Image(systemName: "angle")
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text("Tilt")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Slider(value: $pitch, in: 0...75, step: 5)
                .tint(Theme.Colors.primary)
            Text("\(Int(pitch))\u{00B0}")
                .font(.caption.monospacedDigit())
                .frame(width: 35, alignment: .trailing)
        }
    }

    // MARK: - Heading

    private var headingSlider: some View {
        HStack {
            Image(systemName: "safari")
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text("Rotate")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Slider(value: $heading, in: 0...360, step: 15)
                .tint(Theme.Colors.primary)
            Text("\(Int(heading))\u{00B0}")
                .font(.caption.monospacedDigit())
                .frame(width: 35, alignment: .trailing)
        }
    }

    // MARK: - Zoom

    private var zoomSlider: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text("Zoom")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Slider(value: $distance, in: 1000...50000, step: 1000)
                .tint(Theme.Colors.primary)
            Text(String(format: "%.0fkm", distance / 1000))
                .font(.caption.monospacedDigit())
                .frame(width: 40, alignment: .trailing)
        }
    }

    // MARK: - Fly Along

    private var flyAlongButton: some View {
        Button {
            onFlyToggle()
        } label: {
            Label(
                isFlying ? "Stop" : "Fly Along Course",
                systemImage: isFlying ? "stop.fill" : "airplane"
            )
            .font(.subheadline.bold())
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(isFlying ? Theme.Colors.danger : Theme.Colors.primary)
    }
}
