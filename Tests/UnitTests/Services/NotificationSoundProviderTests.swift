import Testing
import UserNotifications
@testable import UltraTrain

@Suite("NotificationSoundProvider Tests")
struct NotificationSoundProviderTests {

    @Test("Default preference returns system default sound")
    func defaultPreferenceReturnsDefault() {
        let sound = NotificationSoundProvider.sound(for: .training, preference: .defaultSound)
        #expect(sound == .default)
    }

    @Test("Custom preference returns named sound")
    func customPreferenceReturnsNamedSound() {
        let sound = NotificationSoundProvider.sound(for: .training, preference: .custom)
        #expect(sound != nil)
        #expect(sound != .default)
    }

    @Test("Silent preference returns nil")
    func silentPreferenceReturnsNil() {
        let sound = NotificationSoundProvider.sound(for: .race, preference: .silent)
        #expect(sound == nil)
    }

    @Test("Each category has a unique custom sound filename")
    func uniqueSoundFilenames() {
        let filenames = NotificationCategory.allCases.map(\.customSoundFilename)
        let uniqueFilenames = Set(filenames)
        #expect(filenames.count == uniqueFilenames.count)
    }

    @Test("Custom sound filenames end with .caf")
    func cafExtension() {
        for category in NotificationCategory.allCases {
            #expect(category.customSoundFilename.hasSuffix(".caf"))
        }
    }

    @Test("NotificationSoundPreference is Codable")
    func codableRoundTrip() throws {
        let original: [NotificationCategory: NotificationSoundPreference] = [
            .training: .custom,
            .race: .silent,
            .recovery: .defaultSound
        ]
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(
            [NotificationCategory: NotificationSoundPreference].self, from: data
        )
        #expect(decoded == original)
    }

    @Test("NotificationCategory displayName is non-empty")
    func displayNameNonEmpty() {
        for category in NotificationCategory.allCases {
            #expect(!category.displayName.isEmpty)
        }
    }

    @Test("AppSettings soundPreference defaults to .defaultSound")
    func settingsDefaultsToDefault() {
        let settings = AppSettings(
            id: .init(),
            trainingRemindersEnabled: true,
            nutritionRemindersEnabled: true,
            autoPauseEnabled: true,
            nutritionAlertSoundEnabled: true,
            stravaAutoUploadEnabled: false,
            stravaConnected: false,
            raceCountdownEnabled: true,
            biometricLockEnabled: false,
            hydrationIntervalSeconds: 1200,
            fuelIntervalSeconds: 2700,
            electrolyteIntervalSeconds: 0,
            smartRemindersEnabled: false,
            saveToHealthEnabled: false,
            healthKitAutoImportEnabled: false,
            pacingAlertsEnabled: true,
            recoveryRemindersEnabled: true,
            weeklySummaryEnabled: true
        )
        #expect(settings.soundPreference(for: .training) == .defaultSound)
        #expect(settings.soundPreference(for: .nutrition) == .defaultSound)
    }
}
