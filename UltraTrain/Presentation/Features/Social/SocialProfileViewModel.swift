import Foundation
import os

@Observable
@MainActor
final class SocialProfileViewModel {

    // MARK: - Dependencies

    private let profileRepository: any SocialProfileRepository
    private let athleteRepository: any AthleteRepository
    private let runRepository: any RunRepository

    // MARK: - State

    var profile: SocialProfile?
    var isLoading = false
    var error: String?
    var isSaving = false

    // Editable fields
    var displayName = ""
    var bio = ""
    var isPublicProfile = false

    // MARK: - Init

    init(
        profileRepository: any SocialProfileRepository,
        athleteRepository: any AthleteRepository,
        runRepository: any RunRepository
    ) {
        self.profileRepository = profileRepository
        self.athleteRepository = athleteRepository
        self.runRepository = runRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil
        do {
            profile = try await profileRepository.fetchMyProfile()
            if let profile {
                displayName = profile.displayName
                bio = profile.bio ?? ""
                isPublicProfile = profile.isPublicProfile
            } else if let athlete = try await athleteRepository.getAthlete() {
                displayName = "\(athlete.firstName) \(String(athlete.lastName.prefix(1)))."
            }
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to load social profile: \(error)")
        }
        isLoading = false
    }

    // MARK: - Save

    func save() async {
        isSaving = true
        error = nil
        do {
            let athlete = try await athleteRepository.getAthlete()
            let runs = try await runRepository.getRecentRuns(limit: 1000)
            let totalDistance = runs.reduce(0) { $0 + $1.distanceKm }
            let totalElevation = runs.reduce(0) { $0 + $1.elevationGainM }

            let updated = SocialProfile(
                id: profile?.id ?? UUID().uuidString,
                displayName: displayName,
                bio: bio.isEmpty ? nil : bio,
                profilePhotoData: profile?.profilePhotoData,
                experienceLevel: athlete?.experienceLevel ?? .intermediate,
                totalDistanceKm: totalDistance,
                totalElevationGainM: totalElevation,
                totalRuns: runs.count,
                joinedDate: profile?.joinedDate ?? Date.now,
                isPublicProfile: isPublicProfile
            )
            try await profileRepository.saveMyProfile(updated)
            profile = updated
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to save social profile: \(error)")
        }
        isSaving = false
    }
}
