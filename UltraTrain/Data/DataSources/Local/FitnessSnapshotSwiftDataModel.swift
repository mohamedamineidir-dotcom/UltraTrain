import Foundation
import SwiftData

@Model
final class FitnessSnapshotSwiftDataModel {
    @Attribute(.unique) var id: UUID
    var date: Date
    var fitness: Double
    var fatigue: Double
    var form: Double
    var weeklyVolumeKm: Double
    var weeklyElevationGainM: Double
    var weeklyDuration: Double
    var acuteToChronicRatio: Double
    var monotony: Double = 0

    init(
        id: UUID,
        date: Date,
        fitness: Double,
        fatigue: Double,
        form: Double,
        weeklyVolumeKm: Double,
        weeklyElevationGainM: Double,
        weeklyDuration: Double,
        acuteToChronicRatio: Double,
        monotony: Double
    ) {
        self.id = id
        self.date = date
        self.fitness = fitness
        self.fatigue = fatigue
        self.form = form
        self.weeklyVolumeKm = weeklyVolumeKm
        self.weeklyElevationGainM = weeklyElevationGainM
        self.weeklyDuration = weeklyDuration
        self.acuteToChronicRatio = acuteToChronicRatio
        self.monotony = monotony
    }
}
