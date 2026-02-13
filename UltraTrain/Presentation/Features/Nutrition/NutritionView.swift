import SwiftUI

struct NutritionView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No Nutrition Plan",
                systemImage: "fork.knife.circle",
                description: Text("Your nutrition plan will be generated alongside your training plan.")
            )
            .navigationTitle("Nutrition")
        }
    }
}
