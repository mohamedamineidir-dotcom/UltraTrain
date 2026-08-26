import SwiftUI

/// The prominent call-to-action footer on the "Predicted Finish Time" card
/// that leads into the evolution/course-map graphics — this feature's core
/// content. Deliberately has NO fill of its own — giving it any flat color
/// (even one sampled from the card's own palette) never quite matched the
/// exact shade the card's diagonal background gradient renders at that
/// specific spot, which read as a seam/color mismatch. Leaving it
/// transparent means it's always pixel-identical to the card behind it —
/// the only separator is a single flat 1px line, and the only "come tap
/// me" cue is a soft pulsing ring around the icon.
struct EvolutionCTAFooter: View {
    @State private var glowPulse = false

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.22))
                    .frame(width: 34, height: 34)
                Circle()
                    .stroke(Theme.Colors.primary.opacity(glowPulse ? 0 : 0.55), lineWidth: 1.5)
                    .frame(width: 34, height: 34)
                    .scaleEffect(glowPulse ? 1.35 : 1.0)
                Image(systemName: "chart.xyaxis.line")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("See your prediction evolve")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text("Training curve & course map")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.Colors.primary)
        }
        .padding(.top, Theme.Spacing.sm + 2)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .top) {
            // A single flat line — no fade, no gradient — is the only
            // separator between the scenario numbers and this row. Bled
            // out to the card's own edges (not this row's narrower,
            // inset content width, and not the screen edge).
            Rectangle()
                .fill(Color.white.opacity(0.14))
                .frame(height: 1)
                .padding(.horizontal, -Theme.Spacing.md)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                glowPulse = true
            }
        }
    }
}
