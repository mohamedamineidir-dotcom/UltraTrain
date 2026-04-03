import Foundation

struct StrengthWorkout: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    let name: String
    let category: StrengthSessionCategory
    let exercises: [StrengthExercise]
    let estimatedDurationMinutes: Int
    let warmUpNotes: String
    let coolDownNotes: String

    init(
        id: UUID = UUID(),
        name: String,
        category: StrengthSessionCategory,
        exercises: [StrengthExercise],
        estimatedDurationMinutes: Int,
        warmUpNotes: String = "5 min dynamic warm-up: leg swings, hip circles, arm circles, bodyweight squats.",
        coolDownNotes: String = "5 min cool-down: foam rolling, static stretches for quads, hamstrings, calves, hip flexors."
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.exercises = exercises
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.warmUpNotes = warmUpNotes
        self.coolDownNotes = coolDownNotes
    }
}

enum StrengthSessionCategory: String, CaseIterable, Sendable, Codable {
    case full
    case maintenance
    case activation

    var displayName: String {
        switch self {
        case .full: "Full Session"
        case .maintenance: "Maintenance"
        case .activation: "Activation & Mobility"
        }
    }

    var icon: String {
        switch self {
        case .full: "dumbbell.fill"
        case .maintenance: "figure.strengthtraining.traditional"
        case .activation: "figure.flexibility"
        }
    }
}
