import SwiftUI

struct PlanGenerationLoadingView: View {
    private let steps: [(icon: String, title: String, subtitle: String)] = [
        ("person.fill", "Analyzing your profile", "Experience, fitness history & goals"),
        ("calendar.badge.clock", "Building periodization", "Base, build, peak & taper phases"),
        ("figure.run", "Generating sessions", "Long runs, intervals & recovery"),
        ("fork.knife", "Preparing nutrition plan", "Race-day fueling strategy")
    ]

    var body: some View {
        FuturisticGenerationView(
            steps: steps,
            accentColor: Theme.Colors.accentColor
        )
    }
}
