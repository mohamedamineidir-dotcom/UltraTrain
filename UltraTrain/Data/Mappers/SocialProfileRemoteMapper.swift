import Foundation

enum SocialProfileRemoteMapper {
    static func toDomain(_ dto: SocialProfileResponseDTO) -> SocialProfile? {
        let formatter = ISO8601DateFormatter()
        guard let joinedDate = formatter.date(from: dto.joinedDate),
              let experienceLevel = ExperienceLevel(rawValue: dto.experienceLevel) else {
            return nil
        }

        return SocialProfile(
            id: dto.id,
            displayName: dto.displayName,
            bio: dto.bio,
            profilePhotoData: nil,
            experienceLevel: experienceLevel,
            totalDistanceKm: dto.totalDistanceKm,
            totalElevationGainM: dto.totalElevationGainM,
            totalRuns: dto.totalRuns,
            joinedDate: joinedDate,
            isPublicProfile: dto.isPublicProfile
        )
    }

    static func toDTO(_ profile: SocialProfile) -> SocialProfileUpdateRequestDTO {
        SocialProfileUpdateRequestDTO(
            displayName: profile.displayName,
            bio: profile.bio,
            isPublicProfile: profile.isPublicProfile
        )
    }
}
