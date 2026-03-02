import SwiftUI
import AudioToolbox

struct NotificationSoundPickerRow: View {
    let category: NotificationCategory
    @Binding var preference: NotificationSoundPreference

    var body: some View {
        HStack {
            Text(category.displayName)
            Spacer()
            Picker("", selection: $preference) {
                Text("Default").tag(NotificationSoundPreference.defaultSound)
                Text("Custom").tag(NotificationSoundPreference.custom)
                Text("Silent").tag(NotificationSoundPreference.silent)
            }
            .pickerStyle(.menu)

            if preference == .custom {
                Button {
                    previewSound()
                } label: {
                    Image(systemName: "speaker.wave.2")
                        .foregroundStyle(Theme.Colors.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func previewSound() {
        guard let url = Bundle.main.url(
            forResource: category.customSoundFilename,
            withExtension: nil
        ) else { return }
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
}
