import SwiftUI

struct IntervalCountdownOverlay: View {
    @ScaledMetric(relativeTo: .largeTitle) private var countdownSize: CGFloat = 120
    @ScaledMetric(relativeTo: .largeTitle) private var goSize: CGFloat = 48

    let seconds: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("\(seconds)")
                    .font(.system(size: countdownSize, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                if seconds == 0 {
                    Text("GO!")
                        .font(.system(size: goSize, weight: .black, design: .rounded))
                        .foregroundStyle(.red)
                }
            }
        }
        .transition(.opacity)
    }
}
