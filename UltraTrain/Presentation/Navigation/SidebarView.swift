import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: Tab

    private var optionalSelection: Binding<Tab?> {
        Binding<Tab?>(
            get: { selectedTab },
            set: { if let tab = $0 { selectedTab = tab } }
        )
    }

    var body: some View {
        List(selection: optionalSelection) {
            Label("Dashboard", systemImage: "house.fill")
                .tag(Tab.dashboard)

            Label("Plan", systemImage: "calendar")
                .tag(Tab.plan)

            Label("Run", systemImage: "figure.run")
                .tag(Tab.run)

            Label("Nutrition", systemImage: "fork.knife")
                .tag(Tab.nutrition)

            Label("Profile", systemImage: "person.fill")
                .tag(Tab.profile)
        }
        .navigationTitle("UltraTrain")
        .listStyle(.sidebar)
    }
}
