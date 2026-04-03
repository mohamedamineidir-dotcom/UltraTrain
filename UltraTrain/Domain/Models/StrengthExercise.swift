import Foundation

struct StrengthExercise: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    let name: String
    let category: StrengthExerciseCategory
    let sets: Int
    let reps: String // e.g. "10-12", "30 sec", "8 per side"
    let notes: String
    let requiresEquipment: Bool

    init(
        id: UUID = UUID(),
        name: String,
        category: StrengthExerciseCategory,
        sets: Int,
        reps: String,
        notes: String = "",
        requiresEquipment: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.sets = sets
        self.reps = reps
        self.notes = notes
        self.requiresEquipment = requiresEquipment
    }
}

enum StrengthExerciseCategory: String, CaseIterable, Sendable, Codable {
    case core
    case lowerBody
    case singleLegStability
    case upperBody
    case plyometric
    case injuryPrevention
    case mobility

    var displayName: String {
        switch self {
        case .core: "Core"
        case .lowerBody: "Lower Body"
        case .singleLegStability: "Single-Leg Stability"
        case .upperBody: "Upper Body"
        case .plyometric: "Plyometric / Power"
        case .injuryPrevention: "Injury Prevention"
        case .mobility: "Mobility"
        }
    }
}
