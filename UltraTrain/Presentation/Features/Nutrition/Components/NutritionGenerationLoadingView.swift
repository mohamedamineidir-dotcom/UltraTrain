import SwiftUI

struct NutritionGenerationLoadingView: View {
    private let steps: [(icon: String, title: String, subtitle: String)] = [
        ("figure.run", "Analyzing race profile", "Distance, elevation & expected duration"),
        ("bolt.fill", "Calculating energy needs", "Calories, carbs & fat oxidation rates"),
        ("drop.fill", "Building hydration strategy", "Fluid intake & electrolyte balance"),
        ("fork.knife", "Finalizing nutrition plan", "Products, timing & gut training schedule")
    ]

    var body: some View {
        FuturisticGenerationView(
            steps: steps,
            accentColor: Theme.Colors.success
        )
    }
}
