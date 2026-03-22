import SwiftUI

struct PostSaveLoadingView: View {
    let onComplete: () -> Void

    private let steps: [(icon: String, title: String, subtitle: String)] = [
        ("chart.bar.fill", "Analyzing your performance", "Processing pace, elevation & heart rate"),
        ("figure.run", "Updating training metrics", "Recalculating fitness & training load"),
        ("calendar.badge.clock", "Optimizing your plan", "Adjusting upcoming sessions")
    ]

    var body: some View {
        PlanUpdateLoadingView(
            steps: steps,
            accentColor: Theme.Colors.success,
            onComplete: onComplete
        )
    }
}
