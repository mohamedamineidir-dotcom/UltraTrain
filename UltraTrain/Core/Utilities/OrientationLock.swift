import UIKit

@MainActor
enum OrientationLock {
    /// The currently allowed orientations. Updated per-screen.
    /// AppDelegate reads this to decide which orientations to support.
    nonisolated(unsafe) static var allowedOrientations: UIInterfaceOrientationMask = .allButUpsideDown

    /// Lock to portrait only (default for most screens on iPhone).
    static func lockPortrait() {
        allowedOrientations = .portrait
    }

    /// Allow all orientations (for run tracking, analysis).
    static func unlockAll() {
        allowedOrientations = .allButUpsideDown
    }

    /// Request the device to rotate back to portrait.
    static func resetToPortrait() {
        allowedOrientations = .portrait
        if #available(iOS 16.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first else { return }
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        }
    }
}
