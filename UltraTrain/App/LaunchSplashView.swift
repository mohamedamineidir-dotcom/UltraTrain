import SwiftUI

/// Mirrors the iOS launch screen visually but renders INSIDE the app
/// process, so it can honour the app's chosen appearance preference
/// rather than only the system appearance.
///
/// iOS launch screens are rendered before the app's code runs, so
/// they can't read in-app settings, they only follow the device's
/// system appearance. When a user has set the app to dark mode on a
/// device that's still in light mode, the iOS launch screen renders
/// the light variant, then the app fades into its dark UI. To smooth
/// that transition we draw this view on top for ~0.4 s, forcing the
/// dark colourScheme so `Color("LaunchBackground")` and
/// `Image("LaunchIcon")` both resolve to their dark variants, same
/// brand-blue background + white runner as the dark launch screen.
struct LaunchSplashView: View {
    var body: some View {
        ZStack {
            Color("LaunchBackground")
                .ignoresSafeArea()
            Image("LaunchIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
        }
        // Forces both the colour and the image asset to resolve to
        // their `dark` luminosity variants regardless of the
        // surrounding environment.
        .environment(\.colorScheme, .dark)
    }
}
