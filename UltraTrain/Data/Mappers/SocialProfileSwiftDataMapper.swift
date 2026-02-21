import Foundation

enum SocialProfileSwiftDataMapper {

    static func toDomain(_ model: SocialProfileSwiftDataModel) -> SocialProfile? {
        guard let level = ExperienceLevel(rawValue: model.experienceLevelRaw) else {
            return nil
        }
        return SocialProfile(
            id: model.id,
            displayName: model.displayName,
            bio: model.bio,
            profilePhotoData: model.profilePhotoData,
            experienceLevel: level,
            totalDistanceKm: model.totalDistanceKm,
            totalElevationGainM: model.totalElevationGainM,
            totalRuns: model.totalRuns,
            joinedDate: model.joinedDate,
            isPublicProfile: model.isPublicProfile
        )
    }

    static func toSwiftData(_ profile: SocialProfile) -> SocialProfileSwiftDataModel {
        SocialProfileSwiftDataModel(
            id: profile.id,
            displayName: profile.displayName,
            bio: profile.bio,
            profilePhotoData: profile.profilePhotoData,
            experienceLevelRaw: profile.experienceLevel.rawValue,
            totalDistanceKm: profile.totalDistanceKm,
            totalElevationGainM: profile.totalElevationGainM,
            totalRuns: profile.totalRuns,
            joinedDate: profile.joinedDate,
            isPublicProfile: profile.isPublicProfile
        )
    }
}
