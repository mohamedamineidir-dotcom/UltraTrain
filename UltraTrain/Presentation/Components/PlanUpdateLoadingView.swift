import SwiftUI

struct PlanUpdateLoadingView: View {
    let steps: [(icon: String, title: String, subtitle: String)]
    let accentColor: Color
    let stepDuration: TimeInterval
    let onComplete: (() -> Void)?

    init(
        steps: [(icon: String, title: String, subtitle: String)],
        accentColor: Color = Theme.Colors.accentColor,
        stepDuration: TimeInterval = 2.0,
        onComplete: (() -> Void)? = nil
    ) {
        self.steps = steps
        self.accentColor = accentColor
        self.stepDuration = stepDuration
        self.onComplete = onComplete
    }

    var body: some View {
        FuturisticGenerationView(
            steps: steps,
            accentColor: accentColor,
            stepDuration: stepDuration,
            loops: false,
            onComplete: onComplete
        )
    }
}
