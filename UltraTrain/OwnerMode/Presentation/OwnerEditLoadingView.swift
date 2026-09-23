#if OWNER_MODE
import SwiftUI

/// Purple-tinted counterpart to `PlanGenerationLoadingView`, shown
/// full-screen while an owner edit is being applied — same
/// `FuturisticGenerationView` machinery, different accent + steps, so
/// it reads unmistakably as "an owner-mode change," not a regular plan
/// regeneration.
struct OwnerEditLoadingView: View {
    private let steps: [(icon: String, title: String, subtitle: String)] = [
        ("wrench.and.screwdriver.fill", "Applying your changes", "Session, blocks, pace & schedule"),
        ("chart.bar.fill", "Recalculating volume", "Weekly totals and D+"),
        ("sparkles", "Refreshing coach notes", "Keeping advice consistent with your edits")
    ]

    var body: some View {
        FuturisticGenerationView(
            steps: steps,
            accentColor: OwnerModeTheme.purple
        )
    }
}
#endif
