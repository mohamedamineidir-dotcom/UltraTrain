import Foundation
import SwiftData
import os

final class LocalSocialProfileRepository: SocialProfileRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func fetchMyProfile() async throws -> SocialProfile? {
        let context = ModelContext(modelContainer)
        var descriptor = FetchDescriptor<SocialProfileSwiftDataModel>()
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else { return nil }
        return SocialProfileSwiftDataMapper.toDomain(model)
    }

    func saveMyProfile(_ profile: SocialProfile) async throws {
        let context = ModelContext(modelContainer)
        let targetId = profile.id
        var descriptor = FetchDescriptor<SocialProfileSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            existing.displayName = profile.displayName
            existing.bio = profile.bio
            existing.profilePhotoData = profile.profilePhotoData
            existing.experienceLevelRaw = profile.experienceLevel.rawValue
            existing.totalDistanceKm = profile.totalDistanceKm
            existing.totalElevationGainM = profile.totalElevationGainM
            existing.totalRuns = profile.totalRuns
            existing.joinedDate = profile.joinedDate
            existing.isPublicProfile = profile.isPublicProfile
        } else {
            let model = SocialProfileSwiftDataMapper.toSwiftData(profile)
            context.insert(model)
        }

        try context.save()
        Logger.social.info("Social profile saved: \(profile.displayName)")
    }

    func fetchProfile(byId profileId: String) async throws -> SocialProfile? {
        let context = ModelContext(modelContainer)
        let targetId = profileId
        var descriptor = FetchDescriptor<SocialProfileSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else { return nil }
        return SocialProfileSwiftDataMapper.toDomain(model)
    }

    func deleteMyProfile() async throws {
        let context = ModelContext(modelContainer)
        var descriptor = FetchDescriptor<SocialProfileSwiftDataModel>()
        descriptor.fetchLimit = 1

        guard let model = try context.fetch(descriptor).first else {
            throw DomainError.socialProfileNotFound
        }

        context.delete(model)
        try context.save()
        Logger.social.info("Social profile deleted")
    }
}
