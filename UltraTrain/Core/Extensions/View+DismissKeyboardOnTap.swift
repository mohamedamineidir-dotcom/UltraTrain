import SwiftUI

extension View {
    /// Dismisses the keyboard when the user taps anywhere that isn't
    /// already handling the tap (a button, a text field, etc.) — the
    /// standard "tap outside to close the keyboard" behavior every
    /// system text input and most apps have, which SwiftUI does not
    /// provide by default. `resignFirstResponder` is resolved against
    /// whichever field currently has focus, regardless of which
    /// `@FocusState` declared it, so this one modifier works app-wide
    /// without any per-field wiring.
    ///
    /// Uses `simultaneousGesture` rather than a plain gesture so it
    /// never blocks taps on buttons/controls underneath it — both the
    /// dismiss and the control's own action fire.
    func dismissKeyboardOnBackgroundTap() -> some View {
        simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}
