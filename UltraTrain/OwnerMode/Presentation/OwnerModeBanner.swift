#if OWNER_MODE
import SwiftUI

/// Unmissable, always-on strip shown above everything else — onboarding,
/// hero landing, the authenticated tabs, all of it — so it's obvious
/// from the very first frame whether the app running on the device is
/// actually the Owner build (as opposed to Xcode having launched the
/// regular UltraTrain scheme by mistake, which looks identical
/// otherwise since it's the same bundle ID overwriting the same
/// install).
struct OwnerModeBanner: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.caption2.bold())
            Text("OWNER MODE")
                .font(.caption2.weight(.heavy))
                .tracking(1)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(Color(red: 0.78, green: 0.1, blue: 0.85))
    }
}
#endif
