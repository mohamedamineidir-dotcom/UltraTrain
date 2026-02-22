import SwiftUI

struct IntervalCountdownOverlay: View {
    let seconds: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("\(seconds)")
                    .font(.system(size: 120, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                if seconds == 0 {
                    Text("GO!")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(.red)
                }
            }
        }
        .transition(.opacity)
    }
}
