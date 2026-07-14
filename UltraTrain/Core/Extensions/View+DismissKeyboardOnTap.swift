import SwiftUI
import UIKit

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
    /// Installs a `UIGestureRecognizer` directly on the window rather than
    /// a SwiftUI `.simultaneousGesture` — a `List`-backed screen (its rows
    /// are UITableViewCells with their own selection gesture recognizer)
    /// stopped responding to any row tap on a real device when this used
    /// `.simultaneousGesture` at the app root, even though `simultaneousGesture`
    /// is documented not to block other gestures. The window-level recognizer
    /// explicitly declares `cancelsTouchesInView = false` and unconditionally
    /// allows simultaneous recognition with every other recognizer, which is
    /// the standard bulletproof recipe for a "tap anywhere, block nothing"
    /// keyboard dismiss.
    func dismissKeyboardOnBackgroundTap() -> some View {
        background(KeyboardDismissBackground())
    }
}

private struct KeyboardDismissBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false

        // The view isn't attached to a window yet at this point — defer
        // one runloop tick so `view.window` resolves.
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window else { return }
            let alreadyInstalled = window.gestureRecognizers?.contains { $0 is KeyboardDismissGestureRecognizer } ?? false
            guard !alreadyInstalled else { return }
            let recognizer = KeyboardDismissGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.dismissKeyboard)
            )
            window.addGestureRecognizer(recognizer)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject {
        @objc func dismissKeyboard() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }
}

/// Configured to never block, delay, or cancel any other gesture recognizer
/// in the window — including UITableView/UICollectionView's own cell
/// selection recognizers that back SwiftUI's `List`.
private final class KeyboardDismissGestureRecognizer: UITapGestureRecognizer, UIGestureRecognizerDelegate {
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
        delegate = self
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
