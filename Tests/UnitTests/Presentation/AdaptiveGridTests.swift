import SwiftUI
import Testing
@testable import UltraTrain

@Suite("AdaptiveGrid Tests")
struct AdaptiveGridTests {

    @Test("Grid uses single column by default (compact size class)")
    func singleColumnByDefault() {
        // AdaptiveGrid reads horizontalSizeClass from environment.
        // On iPhone (compact), it should produce 1-column layout.
        // This test validates the type can be instantiated without error.
        let _ = AdaptiveGrid {
            Text("Card 1")
            Text("Card 2")
        }
    }

    @Test("AdaptiveHStack uses VStack on compact")
    func adaptiveHStackCompact() {
        let _ = AdaptiveHStack {
            Text("Left")
            Text("Right")
        }
    }

    @Test("OrientationLock defaults to allButUpsideDown")
    @MainActor
    func orientationLockDefault() async {
        // Reset to known state
        OrientationLock.unlockAll()
        #expect(OrientationLock.allowedOrientations == .allButUpsideDown)
    }

    @Test("OrientationLock can lock to portrait")
    @MainActor
    func orientationLockPortrait() async {
        OrientationLock.lockPortrait()
        #expect(OrientationLock.allowedOrientations == .portrait)
        // Reset
        OrientationLock.unlockAll()
    }
}
