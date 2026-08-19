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

    @OptionalField(key: "bio")
    var bio: String?

    @Field(key: "is_public_profile")
    var isPublicProfile: Bool

    @Field(key: "display_name")
    var displayName: String

    /// Self-reported — neither ITRA nor UTMB expose an API to look these
    /// up, so this only ever reflects what the athlete entered from their
    /// own profile.
    @OptionalField(key: "itra_index")
    var itraIndex: Double?

    @OptionalField(key: "itra_index_updated_at")
    var itraIndexUpdatedAt: Date?

    @OptionalField(key: "previous_itra_index")
    var previousItraIndex: Double?

    @OptionalField(key: "previous_itra_index_updated_at")
    var previousItraIndexUpdatedAt: Date?

    @OptionalField(key: "utmb_index")
    var utmbIndex: Double?

    @OptionalField(key: "utmb_index_updated_at")
    var utmbIndexUpdatedAt: Date?

    @OptionalField(key: "previous_utmb_index")
    var previousUtmbIndex: Double?

    @OptionalField(key: "previous_utmb_index_updated_at")
    var previousUtmbIndexUpdatedAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {
        self.isPublicProfile = true
        self.displayName = ""
    }
}
