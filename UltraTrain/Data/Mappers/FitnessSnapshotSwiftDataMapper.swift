import Foundation

enum FitnessSnapshotSwiftDataMapper {

    static func toDomain(_ model: FitnessSnapshotSwiftDataModel) -> FitnessSnapshot {
        FitnessSnapshot(
            id: model.id,
            date: model.date,
            fitness: model.fitness,
            fatigue: model.fatigue,
            form: model.form,
            weeklyVolumeKm: model.weeklyVolumeKm,
            weeklyElevationGainM: model.weeklyElevationGainM,
            weeklyDuration: model.weeklyDuration,
            acuteToChronicRatio: model.acuteToChronicRatio,
            monotony: model.monotony
        )
    }

    static func toSwiftData(_ snapshot: FitnessSnapshot) -> FitnessSnapshotSwiftDataModel {
        FitnessSnapshotSwiftDataModel(
            id: snapshot.id,
            date: snapshot.date,
            fitness: snapshot.fitness,
            fatigue: snapshot.fatigue,
            form: snapshot.form,
            weeklyVolumeKm: snapshot.weeklyVolumeKm,
            weeklyElevationGainM: snapshot.weeklyElevationGainM,
            weeklyDuration: snapshot.weeklyDuration,
            acuteToChronicRatio: snapshot.acuteToChronicRatio,
            monotony: snapshot.monotony
        )
    }
}
