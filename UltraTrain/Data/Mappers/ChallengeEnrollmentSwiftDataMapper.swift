import Foundation

enum ChallengeEnrollmentSwiftDataMapper {

    static func toDomain(_ model: ChallengeEnrollmentSwiftDataModel) -> ChallengeEnrollment? {
        guard let status = ChallengeStatus(rawValue: model.statusRaw) else { return nil }
        return ChallengeEnrollment(
            id: model.id,
            challengeDefinitionId: model.challengeDefinitionId,
            startDate: model.startDate,
            status: status,
            completedDate: model.completedDate
        )
    }

    static func toSwiftData(_ enrollment: ChallengeEnrollment) -> ChallengeEnrollmentSwiftDataModel {
        ChallengeEnrollmentSwiftDataModel(
            id: enrollment.id,
            challengeDefinitionId: enrollment.challengeDefinitionId,
            startDate: enrollment.startDate,
            statusRaw: enrollment.status.rawValue,
            completedDate: enrollment.completedDate
        )
    }
}
