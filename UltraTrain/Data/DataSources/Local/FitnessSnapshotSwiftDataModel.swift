import Foundation
import SwiftData

@Model
final class FitnessSnapshotSwiftDataModel {
    var id: UUID = UUID()
    var date: Date = Date()
    var fitness: Double = 0
    var fatigue: Double = 0
    var form: Double = 0
    var weeklyVolumeKm: Double = 0
    var weeklyElevationGainM: Double = 0
    var weeklyDuration: Double = 0
    var acuteToChronicRatio: Double = 0
    var monotony: Double = 0
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        fitness: Double = 0,
        fatigue: Double = 0,
        form: Double = 0,
        weeklyVolumeKm: Double = 0,
        weeklyElevationGainM: Double = 0,
        weeklyDuration: Double = 0,
        acuteToChronicRatio: Double = 0,
        monotony: Double = 0,
        updatedAt: Date = Date()
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
        self.updatedAt = updatedAt
    }
}
