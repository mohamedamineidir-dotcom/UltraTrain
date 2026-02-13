import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Athlete") {
                    Label("Complete onboarding to see your profile", systemImage: "person.crop.circle")
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Section("Races") {
                    Label("No races configured", systemImage: "flag.checkered")
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Section("App") {
                    Label("Settings", systemImage: "gearshape")
                    Label("About", systemImage: "info.circle")
                }
            }
            .navigationTitle("Profile")
        }
    }
}
