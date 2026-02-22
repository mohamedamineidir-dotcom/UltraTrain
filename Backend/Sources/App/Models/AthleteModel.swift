import Fluent
import Vapor

final class AthleteModel: Model, Content, @unchecked Sendable {
    static let schema = "athletes"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: UserModel

    @Field(key: "first_name")
    var firstName: String

    @Field(key: "last_name")
    var lastName: String

    @Field(key: "date_of_birth")
    var dateOfBirth: Date

    @Field(key: "weight_kg")
    var weightKg: Double

    @Field(key: "height_cm")
    var heightCm: Double

    @Field(key: "resting_heart_rate")
    var restingHeartRate: Int

    @Field(key: "max_heart_rate")
    var maxHeartRate: Int

    @Field(key: "experience_level")
    var experienceLevel: String

    @Field(key: "weekly_volume_km")
    var weeklyVolumeKm: Double

    @Field(key: "longest_run_km")
    var longestRunKm: Double

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}
}
